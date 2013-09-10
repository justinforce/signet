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
    # add the route to the blacklist. e.g.
    #
    #   get '/csr_gen/:mac.pem' do |mac|
    #     # ...do stuff...
    #   end
    #   authentication_blacklist << '^\/csr_gen\/.*.pem$'
    #
    def self.authentication_blacklist
      @@authentication_blacklist ||= []
    end

    private

    def authenticate
      pass if in_authentication_blacklist? request.path_info
      halt_with :no_auth  if params[:auth].nil?
      halt_with :bad_auth unless Authenticator.valid_identity_key? params[:auth]
    end

    def in_authentication_blacklist?(path)
      @@authentication_blacklist.find do |match|
        Regexp.new(match) =~ path
      end
    end
  end
end
