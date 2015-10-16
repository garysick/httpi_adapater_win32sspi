require 'base64'
require 'httpi'
require 'net/http'
require 'win32-sspi'
require 'negotiate/client'
require_relative '../auth/config_sspi'

module HTTPI
  module Adapter
    class Win32SSPI < Base
      register :win32_sspi
      
      def initialize(req)
        @request = req
        @sspi_client = create_sspi_client(req)
        @client = create_http_client(req)
      end
      
      attr_reader :client
      attr_reader :sspi_client
      
      def request(method)
        unless REQUEST_METHODS.include? method
          raise NotSupportedError, "Net::HTTP does not support custom HTTP methods"
        end

        http_req = convert_to_http_request(method,@request)
        response = perform_request(@client, @sspi_client, http_req)
        convert_to_httpi_response(response)
      end
      
      private
      
      def create_sspi_client(request)
        return nil unless :sspi == request.auth.type
        
        options = request.auth.sspi.first
        Win32::SSPI::Negotiate::Client.new(options)
      end
      
      def create_http_client(request)
        if request.auth.digest?
          raise NotSupportedError, "Net::HTTP does not support HTTP digest authentication"
        end

        if request.proxy
          http = Net::HTTP.new(request.url.host, request.url.port,
            request.proxy.host, request.proxy.port, request.proxy.user, request.proxy.password)
        else
          http = Net::HTTP.new(request.url.host, request.url.port)
        end

        http.open_timeout = request.open_timeout if request.open_timeout
        http.read_timeout = request.read_timeout if request.read_timeout

        if request.auth.ssl?
          ssl = request.auth.ssl
          unless ssl.verify_mode == :none
            http.ca_file = ssl.ca_cert_file if ssl.ca_cert_file
          end

          http.key = ssl.cert_key
          http.cert = ssl.cert

          http.verify_mode = ssl.openssl_verify_mode
          http.ssl_version = ssl.ssl_version if ssl.ssl_version
        end
        
        http
      end
      
      def perform_request(http_client,sspi_client,http_req)
        token = nil
        http_resp = nil
        http_client.start do |http|
          sspi_client.http_authenticate do |header|
            http_req['Authorization'] = header
            http_resp = http_client.request(http_req)
            http_resp['www-authenticate']
          end
        end
        http_resp
      end
      
      def convert_to_http_request(type,req)
        request_class = case type
          when :get    then Net::HTTP::Get
          when :post   then Net::HTTP::Post
          when :head   then Net::HTTP::Head
          when :put    then Net::HTTP::Put
          when :delete then Net::HTTP::Delete
        end

        request = request_class.new(req.url, req.headers)
        request.body = req.body
        request
      end
      
      def convert_to_httpi_response(resp)
        headers = resp.to_hash
        headers.each do |key, value|
          headers[key] = value[0] if value.size <= 1
        end
        body = (resp.body.kind_of?(Net::ReadAdapter) ? "" : resp.body)
        Response.new(resp.code, headers, body)
      end
    end
  end
end
