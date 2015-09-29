require 'httpi'
require 'httpi/auth/config_sspi'
require 'test-unit'

HTTPI.log = false

class TC_HttpiAuth < Test::Unit::TestCase
  def test_auth_sspi
    req = HTTPI::Request.new("http://virttual-server.gas.local:3005/test")
    req.auth.sspi( {:spn => "HTTP/virtual-server.gas.local"} )
    
    assert req.auth.sspi?
    refute req.auth.sspi.empty?
    assert_equal "HTTP/virtual-server.gas.local", req.auth.sspi.first[:spn]
    assert HTTPI::Auth::Config::TYPES.include?(:sspi)
  end
end
