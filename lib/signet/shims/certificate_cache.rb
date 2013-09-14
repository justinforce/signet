require 'redis'

module Signet
  module Shims
    class CertificateCache

      def self.push(cert, ttl=60)
        key = key_for cert
        redis.set    key, cert.to_pem
        redis.expire key, ttl
      end

      def self.pop(key)
        cert = redis.get key
        redis.del key
        cert
      end

      private

      def self.redis
        @@redis ||= Redis.new
      end

      # The key for a certificate is the MAC address, which is the first part of
      # the common name (CN) in the subject. So a subject of
      #
      # C=US, ST=California, O=Example, OU=Example Unit, \
      #   CN=00:11:22:33:44:55/emailAddress=demo@example.com
      #
      # yields a key of '00:11:22:33:44:55'
      #
      # Incidentally, this also works fine with other formats. So a subject of
      #
      # C=US, ST=California, O=Example, OU=Example Unit, CN=some-box
      #
      # yields a key of 'some-box' as you'd expect.
      #
      def self.key_for(cert)
        cert.subject.to_a.find{|key, _| key == 'CN' }[1].split('/')[0]
      end
    end
  end
end
