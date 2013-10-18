require 'signet/authenticator'
require 'signet/configuration'
require 'sinatra/base'

module Signet
  class MiddlewareBase < Sinatra::Base

    include Signet::Configuration

    before do

      # XXX I hate that this is in here because it's really part of a shim, but
      # I can't figure out another way to do it just now. This loads first, so
      # the shim's before filters get appended, and I just can't figure out how
      # to prepend them. In the future, I want to discover and fix this without
      # wedging shim stuff into the main app.
      params[:auth] ||= params[:identity_key]

      authenticate
    end

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
    #   authentication_exemptions << /^\/csr_gen\/.*.pem$/
    #
    def self.authentication_exemptions
      @@authentication_exemptions ||= []
    end

    private

    def authenticate
      pass if exempt_from_authentication?
      halt_with :no_auth  if params[:auth].nil? and no_client_certificate?
      unless Authenticator.valid_client_certificate?(request) or Authenticator.valid_identity_key?(params[:auth])
        halt_with :bad_auth
      end
    end

    def exempt_from_authentication?
      !!@@authentication_exemptions.find do |match|
        match =~ request.path_info
      end
    end

    def no_client_certificate?
      ssl_client_verify.nil? or ssl_client_verify == 'NONE'
    end

    def ssl_client_verify
      request.env["HTTP_#{config.http.ssl_client_verify_header}"]
    end
  end
end
