require 'minitest'
require 'minitest/autorun'
require 'httpi'
require 'httpi/adapter/win32sspi'

HTTPI.log = false

class TC_HttpiAdapterWin32SSPI < MiniTest::Test
  RequestURI = "http://virtual-pc-serv.bpa.local:3005/test"
  RequestSPN = "HTTP/virtual-pc-serv.bpa.local"
  TestHeaderName = "Test-Header"
  TestHeader = "some junk"
  RemoteUserHdrName = "Remote-User"
  RemoteUserHdr = "johny d"
  FakeAuth = 'YIIxckdlsleodllsleoeoo49dldleo490'
  AuthenticateHdrName = "www-authenticate"
  AuthenticateHdr = "Negotiate #{FakeAuth}"
  
  def test_load_adapter
    request = HTTPI::Request.new(RequestURI)
    request.auth.sspi(spn:RequestSPN)
    adapter = HTTPI.send(:load_adapter,:win32_sspi,request)
    assert_equal "HTTPI::Adapter::Win32SSPI", adapter.class.name
    assert_equal "Win32::SSPI::Negotiate::Client", adapter.sspi_client.class.name
    assert_equal URI.parse(RequestURI), request.url
  end
  
  def with_mock_adapter
    adapter_klass = create_mock_adapter
    HTTPI::Adapter.register(:win32_sspi, adapter_klass, {})

    yield adapter_klass if block_given?

  ensure
    HTTPI::Adapter.register(:win32_sspi,HTTPI::Adapter::Win32SSPI,{})
  end

  def test_get
    with_mock_adapter do |adapter_klass|
      request = HTTPI::Request.new(RequestURI)
      request.auth.sspi(spn:RequestSPN)
      request.headers[TestHeaderName] = TestHeader
      request.headers[RemoteUserHdrName] = RemoteUserHdr

      response = HTTPI::get(request, :win32_sspi)

      assert_equal 'HTTPI::Response', response.class.name
      assert_equal 200, response.code
      assert_equal 'hello test', response.body
      assert_equal 1, response.headers.size
      assert_equal AuthenticateHdr, response.headers[AuthenticateHdrName]

      assert_equal request.url.host, adapter_klass.read_state(:http).address
      assert_equal request.url.port, adapter_klass.read_state(:http).port
      assert_equal 'Win32::SSPI::Negotiate::Client', adapter_klass.read_state(:adapter_client_klass)

      http_req = adapter_klass.read_state(:http_request)
      assert_equal 'Net::HTTP::Get', http_req.class.name
      assert_equal "virtual-pc-serv.bpa.local", http_req.uri.host
      assert_equal 3005, http_req.uri.port
      assert_equal "/test", http_req.uri.path
      
      assert_equal TestHeader, http_req[TestHeaderName]
      assert_equal RemoteUserHdr, http_req[RemoteUserHdrName]
    end
  end

  def test_get_with_query_parameter
    with_mock_adapter do |adapter_klass|
      request = HTTPI::Request.new(RequestURI)
      request.auth.sspi(spn:RequestSPN)
      request.query ="q=query"
      request.headers[TestHeaderName] = TestHeader
      request.headers[RemoteUserHdrName] = RemoteUserHdr

      response = HTTPI::get(request, :win32_sspi)

      assert_equal 'HTTPI::Response', response.class.name
      assert_equal 200, response.code
      assert_equal 'hello test', response.body
      assert_equal 1, response.headers.size
      assert_equal AuthenticateHdr, response.headers[AuthenticateHdrName]

      assert_equal request.url.host, adapter_klass.read_state(:http).address
      assert_equal request.url.port, adapter_klass.read_state(:http).port
      assert_equal 'Win32::SSPI::Negotiate::Client', adapter_klass.read_state(:adapter_client_klass)

      http_req = adapter_klass.read_state(:http_request)
      assert_equal 'Net::HTTP::Get', http_req.class.name
      assert_equal "virtual-pc-serv.bpa.local", http_req.uri.host
      assert_equal 3005, http_req.uri.port
      assert_equal "/test", http_req.uri.path
      assert_equal "q=query", http_req.uri.query
      
      assert_equal TestHeader, http_req[TestHeaderName]
      assert_equal RemoteUserHdr, http_req[RemoteUserHdrName]
    end
  end

  def test_post
    with_mock_adapter do |adapter_klass|
      request = HTTPI::Request.new(RequestURI)
      request.auth.sspi(spn:RequestSPN)
      request.body = "firstname=tom&lastname=johnson"
      request.headers[TestHeaderName] = TestHeader
      request.headers[RemoteUserHdrName] = RemoteUserHdr

      response = HTTPI::post(request, :win32_sspi)

      assert_equal 'HTTPI::Response', response.class.name
      assert_equal 200, response.code
      assert_equal 'hello test', response.body
      assert_equal 1, response.headers.size
      assert_equal AuthenticateHdr, response.headers[AuthenticateHdrName]

      assert_equal request.url.host, adapter_klass.read_state(:http).address
      assert_equal request.url.port, adapter_klass.read_state(:http).port
      assert_equal 'Win32::SSPI::Negotiate::Client', adapter_klass.read_state(:adapter_client_klass)

      http_req = adapter_klass.read_state(:http_request)
      assert_equal 'Net::HTTP::Post', http_req.class.name
      assert_equal "virtual-pc-serv.bpa.local", http_req.uri.host
      assert_equal 3005, http_req.uri.port
      assert_equal "/test", http_req.uri.path
      assert_equal "firstname=tom&lastname=johnson", http_req.body
      
      assert_equal TestHeader, http_req[TestHeaderName]
      assert_equal RemoteUserHdr, http_req[RemoteUserHdrName]
    end
  end

  def create_mock_adapter
    klass = Class.new(MockWin32SSPIAdapter)
  end
end

class MockWin32SSPIAdapter < HTTPI::Adapter::Win32SSPI
  def perform_request(client,sspi,http_req)
    self.class.capture_state(:http, client)
    self.class.capture_state(:adapter_client_klass, sspi.class.name)
    self.class.capture_state(:http_request, http_req)
    self.class.create_mock_response
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
    resp[TC_HttpiAdapterWin32SSPI::AuthenticateHdrName] = [TC_HttpiAdapterWin32SSPI::AuthenticateHdr]
    resp
  end
end