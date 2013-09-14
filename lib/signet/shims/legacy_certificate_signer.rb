require 'sinatra/base'
require 'signet/middleware_base'
require 'signet/shims/certificate_cache'

module Signet
  module Shims
    class LegacyCertificateSigner < Signet::MiddlewareBase

      # The legacy certificate signer system works like this:
      #
      # 1. Client POSTs a CSR to the server
      # 2. Server creates a certificate
      # 3. Client GETs the certificate
      #
      # This implementation allows for a race condition since the certificate
      # creation is apparently done in a different thread than the web services
      # that accept the POST and serve the GET. The client can try to get the
      # certificate before or while it's being generated. We'll address this.
      #
      # This shim works like this:
      #
      # 1. Client POSTs a CSR to the server
      #     A. Server creates certificate
      #     B. Server stores certificate in cache
      #     C. Server responsds with a 200 status
      # 2. Client GETs the certificate
      #     A. Server pops the certificate from the cache (fetch and delete)
      #     B. Server responds with the certificate with a 200 status
      #
      # Signet will return 200 only after it's created the certificate, and this
      # shim will return 200 only after the certificate is stored in the cache.
      # Therefore, the race condition is not possible.

      post '/csr/signme' do
        halt_with :bad_csr if params[:csr].nil?
        CertificateCache.push CertificateAuthority.sign(csr)
        200
      end

      get '/csr_gen/:mac.pem' do |mac|
        CertificateCache.pop(mac) || 404
      end
      authentication_exemptions << /^\/csr_gen\/.*.pem$/

      private

      def csr
        OpenSSL::X509::Request.new File.read(params[:csr][:tempfile])
      end
    end
  end
end
