require 'spec_helper'
require 'signet/server'
require 'support/http_helpers'

describe Signet::Server do

  include HTTPHelpers
  include Rack::Test::Methods

  describe 'authentication' do

    it 'forbids access without authentication' do
      csr_post 'auth' => nil
      last_response.status.should == status_code(:bad_request)
    end

    it 'forbids access with invalid authentication' do
      csr_post 'auth' => 'invalid auth'
      last_response.status.should == status_code(:forbidden)
    end

    it 'allows access with valid authentication' do
      csr_post
      last_response.status.should_not == status_code(:forbidden)
    end
  end

  it 'accepts POSTs to /csr' do
    csr_post
    last_response.status.should_not == status_code(:not_found)
  end

  it 'does not accept GETs to /csr' do
    get "https://example.com/csr?auth=#{valid_user.identity_key}"
    last_response.status.should == status_code(:not_found)
  end

  it 'requires the csr parameter' do
    csr_post 'csr' => nil
    last_response.status.should == status_code(:bad_request)
  end

  it 'returns 400 BAD REQUEST when the certificate signing request is malformed' do
    csr_post 'csr' => 'bad CSR!'
    last_response.status.should == status_code(:bad_request)
  end

  it 'generates a certificate for a valid certificate signing request' do
    csr_post
    expect { OpenSSL::X509::Certificate.new(last_response.body) }.not_to raise_error
  end
end
