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
        @sspi_client = nil
        if :sspi == req.auth.type
          options = req.auth.sspi.first
          spn = options[:spn] rescue nil
          raise "Must specify a spn to use the RubySSPI Adapter see req.auth.sspi(args)" if spn.nil?
          @sspi_client = Win32::SSPI::Negotiate::Client.new(spn,options)
        end
        @client = Net::HTTP.new(req.url.host,req.url.port)
        @request = req
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
      
      def perform_request(http_client,sspi_client,http_req)
        token = nil
        http_resp = nil
        http_client.start do |http|
          while sspi_client.authenticate_and_continue?(token)
            http_req['Authorization'] = "#{sspi_client.auth_type} #{Base64.strict_encode64(sspi_client.token)}"
            http_resp = http_client.request(http_req)
            header = http_resp['www-authenticate']
            if header
              sspi_client.auth_type, token = header.split(' ')
              token = Base64.strict_decode64(token)
            end
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
