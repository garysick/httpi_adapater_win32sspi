require 'httpi'
require 'net/http'
require 'win32/sspi/http_client'

module HTTPI
  module Adapter
    class RubySSPI < Base
      register :ruby_sspi
      
      def initialize(req)
        @client = Win32::SSPI::HttpClient.new
        @http = Net::HTTP.new(req.url.host,req.url.port)
        @request = req
      end
      
      attr_reader :client
      
      def request(method)
        unless REQUEST_METHODS.include? method
          raise NotSupportedError, "Net::HTTP does not support custom HTTP methods"
        end

        http_req = convert_to_http_request(method,@request)
        response = perform_request(@http, @client, http_req)
        convert_to_httpi_response(response)
      end
      
      private
      
      def perform_request(http,client,http_req)
        response = client.request_with_authorization(http,http_req)
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
