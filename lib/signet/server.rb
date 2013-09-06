require 'signet/certificate_signer'
require 'sinatra/base'

module Signet
  class Server < Sinatra::Base
    use Signet::CertificateSigner
  end
end
