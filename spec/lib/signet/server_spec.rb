require 'spec_helper'
require 'signet/certificate_signer'
require 'signet/server'
require 'signet/shims/legacy_certificate_signer'

describe Signet::Server do

  EXPECTED_MIDDLEWARE = [
    Signet::CertificateSigner,
    Signet::Shims::LegacyCertificateSigner,
  ]

  let :detected_middleware do
    Signet::Server.instance_variable_get(:@middleware).flatten.reject { |klass| klass.nil? }
  end

  # Check that
  #   1. All expected middleware is detected
  #   2. All detected middleware is expected
  #
  it 'includes the appropriate middleware' do
    EXPECTED_MIDDLEWARE.each { |klass| detected_middleware.should include klass }
    detected_middleware.each { |klass| EXPECTED_MIDDLEWARE.should include klass }
  end
end
