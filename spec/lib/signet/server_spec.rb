require 'spec_helper'
require 'signet/server'

describe Signet::Server do

  def middleware
    @middleware ||= Signet::Server.instance_variable_get(:@middleware).flatten
  end

  it 'includes the CertificateSigner middleware' do
    middleware.should include Signet::CertificateSigner
  end
end
