require 'support/openssl_helpers'

module HTTPHelpers

  include OpenSSLHelpers

  ##
  # Returns the RSpec subject which will be the middleware or app that is being
  # spec-ed when Rack::Test::Methods methods call `app`.
  #
  def app
    subject # inherited from RSpec::Core::Subject::ExampleMethods
  end

  def status_code(symbol)
    Rack::Utils.status_code symbol
  end

  def app_request(type, route, overrides={})
    default_params = {
      'auth' => valid_user.identity_key,
    }
    send type, "https://example.com#{route}", default_params.merge(overrides)
  end

  def app_get(route='/', overrides={})
    app_request :get, route, overrides
  end

  def app_post(route='/', overrides={})
    app_request :post, route, overrides
  end

  def csr_post(overrides={})
    default_params = {
      'csr'   => valid_csr,
    }
    app_post '/csr', default_params.merge(overrides)
  end

  def signme_post(overrides={})
    default_params = {
    }
    app_post '/csr/signme', default_params.merge(overrides)
  end
end
