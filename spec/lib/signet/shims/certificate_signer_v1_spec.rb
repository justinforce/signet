require 'spec_helper'
require 'support/http_helpers'
require 'signet/shims/certificate_signer_v1'

describe Signet::Shims::CertificateSignerV1 do

  include HTTPHelpers
  include Rack::Test::Methods

  describe 'POST /csr/signme' do

    before :each do
      signme_post
    end

    it 'creates a certificate in the certificate cache'
  end

  describe 'GET /csr/error' do

    it 'routes' do
      app_get '/csr/error'
      last_response.body.should =~ /ERROR/
    end

    it 'I do not know what it does yet.'
  end

  describe 'GET /csr_gen/:mac.pem' do

    it 'routes' do
      mac = '00:11:22:33:44:55'
      app_get "/csr_gen/#{mac}.pem"
      last_response.body.should =~ /MAC #{mac}/
    end

    it 'retrieves the certificate from the certificate cache'
  end
end
