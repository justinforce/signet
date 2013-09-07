require 'signet/certificate_signer'
require 'signet/shims/certificate_signer_v1'
require 'sinatra/base'

module Signet
  class Server < Sinatra::Base
    use Signet::CertificateSigner
    use Signet::Shims::CertificateSignerV1
  end
end
