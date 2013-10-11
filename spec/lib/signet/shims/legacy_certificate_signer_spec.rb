require 'spec_helper'
require 'signet/shims/legacy_certificate_signer'
require 'support/http_helpers'
require 'support/openssl_helpers'

describe Signet::Shims::LegacyCertificateSigner do

  include HTTPHelpers
  include Rack::Test::Methods

  let :cert do
    valid_certificate
  end

  describe 'POST /csr/signme' do

    context 'success' do

      it 'creates a certificate in the certificate cache' do
        Signet::CertificateAuthority.should_receive(:sign).and_return cert
        Signet::Shims::CertificateCache.should_receive(:push).with(cert)
        temp_csr_file do |path|
          app_post '/csr/signme', 'csr' => Rack::Test::UploadedFile.new(path, 'text/plain')
        end
      end

      it 'returns a 200 OK status' do
        temp_csr_file do |path|
          app_post '/csr/signme', 'csr' => Rack::Test::UploadedFile.new(path, 'text/plain')
        end
        last_response.status.should == 200
      end
    end

    context 'when authentication fails' do
      it 'returns a 403 Forbidden status' do
        app_post '/csr/signme', 'auth' => 'BAD AUTH'
        last_response.status.should == 403
      end
    end

    context 'when the request is malformed' do
      it 'returns a 400 Bad Request status' do
        app_post '/csr/signme', 'csr' => nil
        last_response.status.should == 400
      end
    end
  end

  describe 'GET /csr_gen/:mac.pem' do

    it 'is exempt from authentication' do
      Signet::Shims::LegacyCertificateSigner.class_eval do
        !!authentication_exemptions.find do |match|
          match =~ '/csr_gen/00:11:22:33:44:55.pem'
        end
      end
    end

    context 'success' do

      let :key do
        Signet::Shims::CertificateCache.send(:key_for, cert)
      end

      before :each do
        Signet::Shims::CertificateCache.push cert
      end

      it 'retrieves the certificate from the certificate cache' do
        Signet::Shims::CertificateCache.should_receive(:pop).with(key)
        app_get "/csr_gen/#{key}.pem"
      end

      it 'sends the certificate in the body' do
        app_get "/csr_gen/#{key}.pem"
        last_response.body.should == cert.to_pem
      end

      it 'returns a 200 OK status' do
        app_get "/csr_gen/#{key}.pem"
        last_response.status.should == 200
      end
    end

    context 'when the certificate is not found' do
      it 'returns a 404 Not Found status' do
        app_get "/csr_gen/BAD_KEY.pem"
        last_response.status.should == 404
      end
    end
  end
end
