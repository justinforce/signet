require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_group 'Source', 'signet/lib'
  add_group 'Specs',  'signet/spec'
end

require 'factory_girl'
require 'find'
require 'openssl'
require 'rack/test'
require 'signet/certificate_authority'
require 'signet/configuration'
require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'
include Signet::Configuration

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
  config.include Rack::Test::Methods
end

FactoryGirl.find_definitions

WebMock.allow_net_connect! # otherwise, it breaks testing integration/client_cli_spec.rb

BASE_SSL_PATH               = File.expand_path("#{__FILE__}../../../ssl/")
PRODUCTION_CONFIG_PATH      = File.expand_path("#{__FILE__}../../../config/production.yml")
POST_URI                    = "http://#{config.client.host}:#{config.client.port}/csr"

CERTIFICATE_PATH            = "#{BASE_SSL_PATH}/#{environment}/client_certificate.pem"
CLIENT_PRIVATE_KEY_PATH     = "#{BASE_SSL_PATH}/#{environment}/client_private_key.pem"
PRODUCTION_CA_CERT_PATH     = "#{BASE_SSL_PATH}/production/ca_certificate.pem"
PRODUCTION_PRIVATE_KEY_PATH = "#{BASE_SSL_PATH}/production/ca_private_key.pem"

INSTALL_PRODUCTION_FILES = <<-PENDING
Install production CA certificate,  private key, and config to
        - #{PRODUCTION_CA_CERT_PATH}
        - #{PRODUCTION_PRIVATE_KEY_PATH}
        - #{PRODUCTION_CONFIG_PATH}
      to run these tests
PENDING

##
# A SilentLogger acts like a Logger but does nothing.
#
class SilentLogger
  def method_missing(meth, *args, &block); end
end

def valid_user
  @valid_user ||= FactoryGirl.build(:valid_user)
end

def production_files_exist?
  [
    PRODUCTION_CA_CERT_PATH,
    PRODUCTION_PRIVATE_KEY_PATH,
    PRODUCTION_CONFIG_PATH
  ].each do |path|
    return false unless File.exist? path
  end
end

def production_private_key_passphrase
  @@production_private_key_passphrase ||= \
    YAML.load_file(PRODUCTION_CONFIG_PATH)['certificate_authority']['passphrase']
end

def production_ca_private_key
  @@production_ca_private_key ||= \
    OpenSSL::PKey::RSA.new File.read(PRODUCTION_PRIVATE_KEY_PATH), production_private_key_passphrase
end

def production_ca_public_key
  @production_ca_public_key ||= production_ca_private_key.public_key
end

def production_ca_certificate
  @production_ca_certificate ||= OpenSSL::X509::Certificate.new File.read(PRODUCTION_CA_CERT_PATH)
end

def unset_configuration
  Signet::Configuration.class_variables.each do |var|
    Signet::Configuration.class_variable_set var, nil
  end
end

def unset_certificate_authority
  Signet::CertificateAuthority.class_variables.each do |var|
    Signet::CertificateAuthority.class_variable_set var, nil
  end
end
