require 'minitest'
require 'minitest/autorun'
require 'httpi'
require 'httpi/auth/config_sspi'

HTTPI.log = false

class TC_HttpiAuth < MiniTest::Test
  def test_auth_sspi
    req = HTTPI::Request.new("http://virttual-pc-serv.bpa.local:3005/test")
    req.auth.sspi( {:sspi_api_klass => "AnythingWillDo"} )
    
    assert req.auth.sspi?
    refute req.auth.sspi.empty?
    assert_equal "AnythingWillDo", req.auth.sspi.first[:sspi_api_klass]
  end
end
