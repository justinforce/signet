require 'sinatra/base'
require 'signet/middleware_base'

module Signet
  module Shims
    class LegacyCertificateSigner < Signet::MiddlewareBase

      # The legacy certificate signer system works like this:
      #
      # 1. Client POSTs a CSR to the server
      # 2. Server creates a certificate
      # 3. Client GETs the certificate
      #
      # This implementation allows for a race condition since the certificate
      # creation is apparently done in a different thread than the web services
      # that accept the POST and serve the GET. The client can try to get the
      # certificate before or while it's being generated. We'll address this.
      #
      # This shim works like this:
      #
      # 1. Client POSTs a CSR to the server
      #     A. Server creates certificate
      #     B. Server stores certificate in cache
      #     C. Server responsds with a 200 status
      # 2. Client GETs the certificate
      #     A. Server pops the certificate from the cache (fetch and delete)
      #     B. Server responds with the certificate with a 200 status
      #
      # Signet will return 200 only after it's created the certificate, and this
      # shim will return 200 only after the certificate is stored in the cache.
      # Therefore, the race condition is not possible.

      post '/csr/signme' do
        begin
          csr = OpenSSL::X509::Request.new File.read(params[:file][:tempfile])
          CertificateAuthority.sign(csr).to_pem
        rescue NoMethodError
        end
      end

      get '/csr_gen/:mac.pem' do |mac|
        "MAC #{mac}"
      end
      authentication_exemptions << /^\/csr_gen\/.*.pem$/

      private

      def csr
        OpenSSL::X509::Request.new File.read(params[:file][:tempfile])
      rescue OpenSSL::X509::RequestError
        halt_with :bad_csr
      end
    end
  end
end
