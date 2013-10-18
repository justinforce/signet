require 'spec_helper'
require 'signet/authenticator'
require 'signet/user'

describe Signet::Authenticator do

  describe '::valid_client_certificate?' do

    # For an explanation of SSL_CLIENT_VERIFY values, see $ssl_client_verify
    # under Embedded Variables at
    # http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_verify_client

    let :no_cert_request do
      OpenStruct.new env: { 'SSL_CLIENT_VERIFY' => 'NONE' }
    end

    let :bad_cert_request do
      OpenStruct.new env: { 'SSL_CLIENT_VERIFY' => 'FAILED' }
    end

    let :good_cert_request do
      OpenStruct.new env: { 'SSL_CLIENT_VERIFY' => 'SUCCESS' }
    end

    it 'fails with no client certificate' do
      Signet::Authenticator.valid_client_certificate?(no_cert_request).should be false
    end

    it 'fails with an invalid client certificate' do
      Signet::Authenticator.valid_client_certificate?(bad_cert_request).should be false
    end

    it 'succeeds with a valid client certificate' do
      Signet::Authenticator.valid_client_certificate?(good_cert_request).should be true
    end
  end

  describe '::valid_identity_key?' do

    it 'fails with an invalid authentication token' do
      Signet::Authenticator.valid_identity_key?('invalid_token').should be false
    end

    it 'succeeds with valid authentication token' do
      Signet::Authenticator.valid_identity_key?(valid_user.identity_key).should be true
    end
  end
end
