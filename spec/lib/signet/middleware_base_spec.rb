require 'spec_helper'
require 'signet/server'
require 'support/http_helpers'

describe Signet::MiddlewareBase do

  include HTTPHelpers
  include Rack::Test::Methods

  let :app do
    Class.new Signet::MiddlewareBase do
      get '/no_auth' do
        200
      end
      authentication_exemptions << /^\/no_auth$/
    end
  end

  describe 'authentication filter' do

    it 'forbids access without authentication' do
      app_post '/fake', 'auth' => nil
      last_response.status.should == status_code(:bad_request)
    end

    it 'forbids access with invalid authentication' do
      app_post '/fake', 'auth' => 'invalid auth'
      last_response.status.should == status_code(:forbidden)
    end

    it 'allows access with valid authentication' do
      app_post '/fake'
      last_response.status.should_not == status_code(:forbidden)
    end

    it 'respects authentication exemptions' do
      app_get '/no_auth', 'auth' => nil
      last_response.status.should == 200
    end

    context 'when a client certificate is sent' do

      it 'authenticates if the certificate is valid' do
        app_post '/fake', { 'auth' => nil }, { 'SSL_CLIENT_VERIFY' => 'SUCCESS' }
        last_response.status.should == 404
      end

      it 'does not authenticate if the certificate is invalid' do
        app_post '/fake', { 'auth' => nil }, { 'SSL_CLIENT_VERIFY' => 'FAILED' }
        last_response.status.should == 403
      end
    end
  end

  describe '#halt_with' do

    let :message do
      Signet::MiddlewareBase::ERRORS[:bad_auth][:message]
    end

    let :status do
      Rack::Utils.status_code Signet::MiddlewareBase::ERRORS[:bad_auth][:status]
    end

    it 'outputs the appropriate message' do
      app_post '/fake', 'auth' => 'invalid auth'
      last_response.body.should =~ /#{message}/
    end

    it 'returns the appropriate status' do
      app_post '/fake', 'auth' => 'invalid auth'
      last_response.status.should == status
    end
  end

  describe '::authentication_exemptions' do

    it 'returns an Array of Regexs matching paths exempt from authentication' do
      app.send(:authentication_exemptions).should include(/^\/no_auth$/)
    end
  end
end
