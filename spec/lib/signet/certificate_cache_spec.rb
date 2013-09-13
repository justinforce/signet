require 'spec_helper'
require 'signet/certificate_cache'
require 'support/openssl_helpers'

describe Signet::CertificateCache do

  include OpenSSLHelpers

  let :cert do
    valid_certificate
  end

  def cache_has?(key)
    !Signet::CertificateCache.send(:redis).get(key).nil?
  end

  describe '::push' do

    it 'pushes the certificate into the cache' do
      Signet::CertificateCache.push cert
      cache_has?(cert.subject).should be true
    end

    it 'allows setting a ttl' do
      # a 0 ttl will expire instantly
      Signet::CertificateCache.push cert, 0
      cache_has?(cert.subject).should be false
    end
  end

  describe '::pop' do

    it 'returns the certificate from the cache' do
      Signet::CertificateCache.push cert
      Signet::CertificateCache.pop(cert.subject).should == cert.to_pem
    end

    it 'removes the certivicate from the cache' do
      Signet::CertificateCache.push cert
      Signet::CertificateCache.pop(cert.subject).should == cert.to_pem
      cache_has?(cert.subject).should be false
    end
  end
end
