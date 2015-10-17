require 'httpi'
require 'httpi/adapter/win32sspi'
require 'test-unit'

HTTPI.log = false

class TC_HttpiAdapterWin32SSPI < Test::Unit::TestCase
  RequestURI = "http://virtual-server.gas.local:3005/test"
  RequestSPN = "HTTP/virtual-server.gas.local"
  TestHeaderName = "Test-Header"
  TestHeader = "some junk"
  RemoteUserHdrName = "Remote-User"
  RemoteUserHdr = "johny d"
  FakeAuth = 'YIIxckdlsleodllsleoeoo49dldleo490'
  AuthenticateHdrName = "www-authenticate"
  AuthenticateHdr = "Negotiate #{FakeAuth}"
  AuthorizationHdrName = "Authorization"
  AuthorizationHdr = AuthenticateHdr
  
  def test_load_adapter
    request = HTTPI::Request.new(RequestURI)
    request.auth.sspi(spn:RequestSPN)
    adapter = HTTPI.send(:load_adapter,:win32_sspi,request)
    assert_equal "HTTPI::Adapter::Win32SSPI", adapter.class.name
    assert_equal "Win32::SSPI::Negotiate::Client", adapter.sspi_client.class.name
    assert_equal URI.parse(RequestURI), request.url
  end
  
  def with_mock_adapter(adapter_klass = create_mock_adapter)
    HTTPI::Adapter.register(:win32_sspi, adapter_klass, {})

    yield adapter_klass if block_given?

  ensure
    HTTPI::Adapter.register(:win32_sspi,HTTPI::Adapter::Win32SSPI,{})
  end
  
  def assert_request_response_attributes(request,response,adapter_klass)
    assert_equal 'HTTPI::Response', response.class.name
    assert_equal 200, response.code
    assert_equal 'hello test', response.body
    assert_equal 1, response.headers.size
    assert_equal AuthenticateHdr, response.headers[AuthenticateHdrName]

    assert_equal request, adapter_klass.read_state(:httpi_request)
    
    sspi_client = adapter_klass.read_state(:sspi_client)
    assert_equal "Win32::SSPI::Negotiate::Client", sspi_client.class.name
    assert_equal 'Negotiate', sspi_client.auth_type
    assert_equal RequestSPN, sspi_client.spn

    http_req = adapter_klass.read_state(:http_request)
    assert_equal "virtual-server.gas.local", http_req.uri.host
    assert_equal 3005, http_req.uri.port
    assert_equal "/test", http_req.uri.path
    
    yield(http_req) if block_given?
    
    assert_equal TestHeader, http_req[TestHeaderName]
    assert_equal RemoteUserHdr, http_req[RemoteUserHdrName]
  end

  def test_get
    with_mock_adapter do |adapter_klass|
      request = HTTPI::Request.new(RequestURI)
      request.auth.sspi(spn:RequestSPN)
      request.headers[TestHeaderName] = TestHeader
      request.headers[RemoteUserHdrName] = RemoteUserHdr

      response = HTTPI::get(request, :win32_sspi)
      
      assert_request_response_attributes(request,response,adapter_klass) do |http_req|
        assert_equal 'Net::HTTP::Get', http_req.class.name
        assert_equal 3, adapter_klass.read_state(:perform_authenticated_request_args).length
        assert_nil adapter_klass.read_state(:perform_http_request_args)
      end
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
      
      assert_request_response_attributes(request,response,adapter_klass) do |http_req|
        assert_equal 'Net::HTTP::Get', http_req.class.name
        assert_equal "q=query", http_req.uri.query
        assert_equal 3, adapter_klass.read_state(:perform_authenticated_request_args).length
        assert_nil adapter_klass.read_state(:perform_http_request_args)
      end
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
      
      assert_request_response_attributes(request,response,adapter_klass) do |http_req|
        assert_equal 'Net::HTTP::Post', http_req.class.name
        assert_equal "firstname=tom&lastname=johnson", http_req.body
        assert_equal 3, adapter_klass.read_state(:perform_authenticated_request_args).length
        assert_nil adapter_klass.read_state(:perform_http_request_args)
      end
    end
  end

  def create_mock_adapter
    Class.new(MockWin32SSPIAdapter)
  end
end

class MockWin32SSPIAdapter < HTTPI::Adapter::Win32SSPI
  def create_sspi_client(request)
    sspi_client = super
    self.class.capture_state(:sspi_client,sspi_client)
    self
  end
  
  def http_authenticate
    yield(TC_HttpiAdapterWin32SSPI::AuthorizationHdr) if block_given?
  end
  
  def create_http_client(request)
    self.class.capture_state(:httpi_request,request)
    self
  end
  
  def perform_authenticated_request(*args)
    self.class.capture_state(:perform_authenticated_request_args,args)
    super
  end
  
  def perform_http_request(*args)
    self.class.capture_state(:perform_http_request_args,args)
    super
  end
  
  def start
    yield self if block_given?
  end
  
  def request(req)
    if req.kind_of?(Symbol)
      return super
    end
    self.class.capture_state(:http_request, req)
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
