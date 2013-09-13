require 'redis'

module Signet
  class CertificateCache

    def self.push(cert, ttl=60)
      key = cert.subject
      redis.set    key, cert.to_pem
      redis.expire key, ttl
    end

    def self.pop(subject)
      cert = redis.get subject
      redis.expire subject, 0
      cert
    end

    private

    def self.redis
      @@redis ||= Redis.new
    end
  end
end
