require 'spec_helper'
require 'signet/shims/legacy_certificate_signer'
require 'support/http_helpers'
require 'support/openssl_helpers'

describe Signet::Shims::LegacyCertificateSigner do

  include HTTPHelpers
  include Rack::Test::Methods

  MAC = '00:11:22:33:44:55'

  let :cert do
    valid_certificate
  end

  describe 'POST /csr/signme' do

    context 'success' do

      it 'creates a certificate in the certificate cache' do
        Signet::CertificateAuthority.should_receive(:sign).and_return cert
        Signet::CertificateCache.should_receive(:push).with(cert)
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

    # TODO remove this do-nothing demo
    it 'routes' do
      app_get "/csr_gen/#{MAC}.pem"
      last_response.body.should =~ /MAC #{MAC}/
    end

    context 'success' do
      it 'retrieves the certificate from the certificate cache'
      it 'sends the certificate in the body'
      it 'returns a 200 OK status'
    end

    context 'when the certificate is not found' do
      it 'returns a 404 Not Found status'
    end
  end
end
