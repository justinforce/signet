require 'spec_helper'
require 'signet/shims/certificate_cache'
require 'support/openssl_helpers'

module Signet
  module Shims

    describe CertificateCache do

      include OpenSSLHelpers

      let :cert do
        valid_certificate
      end

      let :key do
        Signet::Shims::CertificateCache.send(:key_for, cert)
      end

      def cache_has?(key)
        !CertificateCache.send(:redis).get(key).nil?
      end

      describe '::push' do

        it 'pushes the certificate into the cache' do
          CertificateCache.push cert
          cache_has?(key).should be true
        end

        it 'allows setting a ttl' do
          # a 0 ttl will expire instantly
          CertificateCache.push cert, 0
          cache_has?(key).should be false
        end
      end

      describe '::pop' do

        it 'returns the certificate from the cache' do
          CertificateCache.push cert
          CertificateCache.pop(key).should == cert.to_pem
        end

        it 'removes the certivicate from the cache' do
          CertificateCache.push cert
          CertificateCache.pop(key).should == cert.to_pem
          cache_has?(key).should be false
        end
      end
    end
  end
end
