require 'spec_helper'
require 'signet/certificate_signer'
require 'support/http_helpers'

describe Signet::CertificateSigner do

  include HTTPHelpers
  include Rack::Test::Methods

  it 'is a subclass of MiddlewareBase' do
    Signet::CertificateSigner.ancestors.should include Signet::MiddlewareBase
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
