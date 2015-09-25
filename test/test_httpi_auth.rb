require 'minitest'
require 'minitest/autorun'
require 'httpi'
require 'httpi/auth/config_sspi'

HTTPI.log = false

class TC_HttpiAuth < MiniTest::Test
  def test_auth_sspi
    req = HTTPI::Request.new("http://virttual-pc-serv.bpa.local:3005/test")
    req.auth.sspi( {:spn => "HTTP/virtual-pc-serv.bpa.local"} )
    
    assert req.auth.sspi?
    refute req.auth.sspi.empty?
    assert_equal "HTTP/virtual-pc-serv.bpa.local", req.auth.sspi.first[:spn]
    assert HTTPI::Auth::Config::TYPES.include?(:sspi)
  end
end
