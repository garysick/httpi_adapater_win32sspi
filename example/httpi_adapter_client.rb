require 'pp'
require 'httpi'
require 'httpi/adapter/rubysspi'

class RubySSPIClient
  def self.run
    request = HTTPI::Request.new("http://virtual-pc-serv.bpa.local:3005/test")
    request.auth.sspi(spn:"HTTP/virtual-pc-serv")
    response = HTTPI::get(request, :ruby_sspi)
    pp response
  end
end

if __FILE__ == $0
  RubySSPIClient.run
end
