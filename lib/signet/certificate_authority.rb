require 'openssl'
require 'securerandom'
require 'signet/configuration'

module Signet

  ##
  # As far as this app is concerned, there is only one CertificateAuthority in
  # the whole world so it makes sense for it to have one and only one state and
  # to call the methods as class methods like you would with Time.now or
  # Math.log. Therefore, we pass calls to missing class methods on to a
  # class-wide instance so we can use this like a library, i.e.
  # CertificateAuthority.private_key instead of
  # CertificateAuthority.new.private_key. Both usages will work, but the terser
  # form is more correct, so use it. All methods are implemented as instance
  # methods because state helps us cache and what-not, and it's much easier to
  # test.
  #
  # While the implementation does maintain state, any method can be called in
  # any order, and will ensure that the proper state is set up as needed.
  #
  class CertificateAuthority

    include Signet::Configuration

    def self.method_missing(meth, *args, &block)
      @@ca ||= new
      @@ca.send(meth, *args, &block)
    end

    ##
    # Signs and returns the CSR
    #
    def sign(csr)
      raise ArgumentError if csr.nil? or !csr.is_a?(OpenSSL::X509::Request)
      certificate_for(csr).sign private_key, OpenSSL::Digest::SHA1.new
    end

    ##
    # Verifies that the certificate was signed by this certificate authority
    #
    def verify?(cert)
      cert.verify public_key
    end

    def private_key
      @@private_key ||= OpenSSL::PKey::RSA.new(
        File.read(private_key_path), config.certificate_authority.passphrase
      )
    end

    def certificate
      @@certificate ||= OpenSSL::X509::Certificate.new(File.read(certificate_path))
    end

    def public_key
      @@public_key ||= private_key.public_key
    end

    def subject
      @@subject ||= certificate.subject
    end

    private

    SSL_EXTENSIONS = [
      [ 'basicConstraints',     'CA:FALSE' ],
      [ 'keyUsage',             'keyEncipherment,dataEncipherment,digitalSignature' ],
      [ 'subjectKeyIdentifier', 'hash' ],
    ]

    def private_key_path
      @@private_key_path ||= "#{ssl_prefix}/#{environment}/ca_private_key.pem"
    end

    def ssl_prefix
      @@ssl_prefix ||= File.expand_path("#{File.dirname(__FILE__)}/../../ssl")
    end

    def certificate_path
      @@certificate_path ||= "#{ssl_prefix}/#{environment}/ca_certificate.pem"
    end

    ##
    # Returns a reasonably unique integer for use as a serial number
    #
    def serial
      (Time.now.to_f * 10_000_000).to_i
    end

    ##
    # Creates a new certificate for the given CSR
    #
    def certificate_for(csr)
      OpenSSL::X509::Certificate.new.tap do |cert|
        set_attributes_on cert, csr
        add_extensions_to cert
      end
    end

    def add_extensions_to(cert)
      OpenSSL::X509::ExtensionFactory.new.tap do |factory|
        factory.subject_certificate = cert
        factory.issuer_certificate  = certificate

        SSL_EXTENSIONS.each do |extension|
          cert.add_extension factory.create_extension extension
        end
      end
    end

    def set_attributes_on(cert, csr)
      now             = Time.now
      cert.subject    = csr.subject
      cert.public_key = csr.public_key
      cert.serial     = serial
      cert.issuer     = subject
      cert.version    = config.certificate_authority.version
      cert.not_before = now
      cert.not_after  = now + config.certificate_authority.expiry_seconds
    end
  end
end
