require 'signet/authenticator'
require 'sinatra/base'

module Signet
  class MiddlewareBase < Sinatra::Base

    before { authenticate }

    protected

    ERRORS = {
      no_auth:  {
        message: 'No auth parameter was supplied',
        status: :bad_request
      },
      bad_auth: {
        message: 'Authentication failed; check your auth parameter.',
        status: :forbidden
      },
      no_csr:   {
        message: 'No csr parameter was supplied',
        status: :bad_request
      },
      bad_csr:  {
        message: "Couldn't parse that csr parameter; are you sure it's a CSR in PEM format?",
        status: :bad_request
      },
    }

    def halt_with(error)
      status, message = ERRORS[error][:status], ERRORS[error][:message]
      logger.error message
      halt Rack::Utils.status_code(status), "#{message}\n"
    end

    private

    def authenticate
      halt_with :no_auth  if params[:auth].nil?
      halt_with :bad_auth unless Authenticator.valid_identity_key? params[:auth]
    end
  end
end
