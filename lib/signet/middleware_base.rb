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

    # An array of regular expressions representing paths that are exempt from
    # authentication. The proper way to use this is to define your route then
    # add the route to the exemptions list. e.g.
    #
    #   get '/csr_gen/:mac.pem' do |mac|
    #     # ...do stuff...
    #   end
    #   authentication_exemptions << '^\/csr_gen\/.*.pem$'
    #
    def self.authentication_exemptions
      @@authentication_exemptions ||= []
    end

    private

    def authenticate
      pass if exempt_from_authentication?
      halt_with :no_auth  if params[:auth].nil?
      halt_with :bad_auth unless Authenticator.valid_identity_key? params[:auth]
    end

    def exempt_from_authentication?
      @@authentication_exemptions.find do |match|
        Regexp.new(match) =~ request.path_info
      end
    end
  end
end
