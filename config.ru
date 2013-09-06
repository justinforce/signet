$: << 'lib'

require 'signet/server'

ENV['RACK_ENV'] ||= 'development'

run Signet::Server.new
