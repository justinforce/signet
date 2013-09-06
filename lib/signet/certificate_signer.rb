require 'signet/certificate_authority'
require 'signet/middleware_base'

module Signet
  class CertificateSigner < MiddlewareBase

    post '/csr' do
      halt_with :no_csr if params[:csr].nil?
      CertificateAuthority.sign(csr).to_pem
    end

    private

    def csr
      OpenSSL::X509::Request.new(params[:csr])
    rescue OpenSSL::X509::RequestError
      halt_with :bad_csr
    end
  end
end
