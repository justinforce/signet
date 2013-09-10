require 'signet/certificate_signer'
require 'signet/shims/legacy_certificate_signer'
require 'sinatra/base'

module Signet
  class Server < Sinatra::Base
    use Signet::CertificateSigner
    use Signet::Shims::LegacyCertificateSigner
  end
end
