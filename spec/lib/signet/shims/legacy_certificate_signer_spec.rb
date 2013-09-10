require 'spec_helper'
require 'support/http_helpers'
require 'signet/shims/legacy_certificate_signer'

describe Signet::Shims::LegacyCertificateSigner do

  include HTTPHelpers
  include Rack::Test::Methods

  MAC = '00:11:22:33:44:55'

  describe 'POST /csr/signme' do

    before :each do
      signme_post
    end

    # TODO remove this do-nothing demo
    it 'routes' do
      app_post '/csr/signme'
      last_response.body.should =~ /SIGNME/
    end

    context 'success' do
      it 'creates a certificate in the certificate cache' do
        pending
        certificate = double OpenSSL::X509::Certificate
        CertificateSigner.should_receive
        Signet::CertificateCache.should_receive(:put)
      end
      it 'returns a 200 OK status'
    end

    context 'when authentication fails' do
      it 'returns a 403 Forbidden status' do
        app_post '/csr/signme', 'auth' => 'BAD AUTH'
        last_response.status.should == 403
      end
    end

    context 'when the request is malformed' do
      it 'returns a 400 Bad Request status'
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
