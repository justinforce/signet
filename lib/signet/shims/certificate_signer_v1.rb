require 'sinatra/base'
require 'signet/middleware_base'

module Signet
  module Shims
    class CertificateSignerV1 < Signet::MiddlewareBase

      post '/csr/signme' do
        'SIGNME'
      end

      get '/csr/error' do
        'ERROR'
      end

      get '/csr_gen/:mac.pem' do |mac|
        "MAC #{mac}"
      end
    end
  end
end
