require 'signet/user'

module Signet
  class Authenticator

    def self.valid_client_certificate?(request)
      request.env['SSL_CLIENT_VERIFY'] == 'SUCCESS'
    end

    def self.valid_identity_key?(identity_key)
      !!User.find_by_identity_key(identity_key)
    end
  end
end
