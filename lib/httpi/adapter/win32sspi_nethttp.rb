require 'base64'
require 'httpi'
require 'net/http'
require 'win32-sspi'
require 'negotiate/client'
require_relative '../auth/config_sspi'

module HTTPI
  module Adapter
    class Win32SSPINetHTTP < NetHTTP

      register :win32_sspi_nethttp
      
      def initialize(req)
        super

        @request = req
        @sspi_client = nil
        if :sspi == req.auth.type
          options = req.auth.sspi.first
          spn = options[:spn] rescue nil
          raise "Must specify a spn to use the Win32SSPI Adapter see req.auth.sspi(args)" if spn.nil?
          @sspi_client = Win32::SSPI::Negotiate::Client.new(spn,options)
        end
      end
      
      attr_reader :sspi_client
      
      def check_net_ntlm_version!
      end

      def negotiate_ntlm_auth(http, &requester)
      end
      
      def perform(http_client, http_request, &block)
        if sspi_client
          token = nil
          while sspi_client.authenticate_and_continue?(token)
            http_request['Authorization'] = "#{sspi_client.auth_type} #{Base64.strict_encode64(sspi_client.token)}"
            http_response = http_client.request(http_request, &block)
            header = http_response['www-authenticate']
            if header
              sspi_client.auth_type, token = header.split(' ')
              token = Base64.strict_decode64(token)
            end
          end
          http_response
        else
          http_client.request(http_request, &block)
        end
      end

      def create_client
        if @request.proxy
          Net::HTTP.new(@request.url.host, @request.url.port,
            @request.proxy.host, @request.proxy.port, @request.proxy.user, @request.proxy.password)
        else
          Net::HTTP.new(@request.url.host, @request.url.port)
        end
      end

      def request_client(type)
        request_class = case type
          when :get    then Net::HTTP::Get
          when :post   then Net::HTTP::Post
          when :head   then Net::HTTP::Head
          when :put    then Net::HTTP::Put
          when :delete then Net::HTTP::Delete
        end

        request_client = request_class.new(@request.url, @request.headers)
        request_client.basic_auth(*@request.auth.credentials) if @request.auth.basic?

        if @request.auth.digest?
          raise NotSupportedError, "Net::HTTP does not support HTTP digest authentication"
        end

        request_client
      end

    end
  end
end
