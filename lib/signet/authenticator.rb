require 'signet/user'
require 'signet/configuration'

module Signet
  class Authenticator

    include Signet::Configuration

    def self.valid_client_certificate?(request)
      request.env["HTTP_#{config.http.ssl_client_verify_header}"] == 'SUCCESS'
    end

    def self.valid_identity_key?(identity_key)
      !!User.find_by_identity_key(identity_key)
    end
  end
end
