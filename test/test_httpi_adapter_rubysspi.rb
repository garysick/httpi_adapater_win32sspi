require 'minitest'
require 'minitest/autorun'
require 'httpi'
require 'adapter/rubysspi'

HTTPI.log = false

class TC_HttpiAdapterRubySSPI < MiniTest::Test
  def test_load_adapter
    request = HTTPI::Request.new("http://virtual-pc-serv.bpa.local:3005/test")
    adapter = HTTPI.send(:load_adapter,:ruby_sspi,request)
    assert_equal "HTTPI::Adapter::RubySSPI", adapter.class.name
    assert_equal "Win32::SSPI::HttpClient", adapter.client.class.name
    assert_equal URI.parse("http://virtual-pc-serv.bpa.local:3005/test"), request.url
  end
  
  FakeAuth = 'YIIxckdlsleodllsleoeoo49dldleo490'

  def test_request_with_sspi_adapter
    HTTPI::Adapter.register(:ruby_sspi,create_mock_adapter,{})
    request = HTTPI::Request.new("http://pc-virtual-serv.bpa.local:3005/test")
    response = HTTPI::get(request, :ruby_sspi)
    assert_equal 200, response.code
    assert_equal 'hello test', response.body
    assert_equal 1, response.headers.size
    assert_equal FakeAuth, response.headers['Authorization']
    
    assert_equal request.url, read_state(:uri)
    assert_equal 'Win32::SSPI::HttpClient', read_state(:adapter_client).class.name
    assert_equal 'Net::HTTP::Get', read_state(:http_request).class.name
   ensure
    HTTPI::Adapter.register(:ruby_sspi,HTTPI::Adapter::RubySSPI,{})
    clear_state
  end
  
  def create_mock_adapter
    klass = Class.new(HTTPI::Adapter::RubySSPI) do
      def perform_request(uri,client,http_req)
        TC_HttpiAdapterRubySSPI.capture_state(:uri,uri)
        TC_HttpiAdapterRubySSPI.capture_state(:adapter_client,client)
        TC_HttpiAdapterRubySSPI.capture_state(:http_request,http_req)

        TC_HttpiAdapterRubySSPI::create_mock_response
      end
    end
  end
  
  def read_state(key)
    self.class.read_state(key)
  end
  
  def clear_state
    self.class.state.clear
  end
  
  def self.state
    @state ||= Hash.new
  end
  
  def self.capture_state(key,value)
    state[key] = value
  end
  
  def self.read_state(key)
    state[key]
  end
  
  def self.create_mock_response
    resp = Class.new(::Hash) do
      def code
        @code ||= 200
      end
      def code=(rhs)
        @code = rhs
      end
      def body
        @body ||= ""
      end
      def body=(rhs)
        @body = rhs
      end
      def headers
        self
      end
      def to_hash
        self
      end
    end.new

    resp.body = "hello test"
    resp['Authorization'] = [FakeAuth]
    resp
  end
end
