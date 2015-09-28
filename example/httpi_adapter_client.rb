require 'pp'
require 'httpi'
require 'httpi/adapter/win32sspi'

class Win32SSPIClient
  def self.run(url)
    uri = URI.parse(url)
    request = HTTPI::Request.new(url)
    request.auth.sspi(spn:"HTTP/#{uri.host}")
    response = HTTPI::get(request, :win32_sspi)
    pp response
  end
end

if __FILE__ == $0
  if ARGV.length < 1
    puts "usage: ruby -Ilib httpi_adapter_client url"
    exit(0)
  end

  Win32SSPIClient.run(ARGV[0])
end
