require 'net/http'
require "json"

module Ttr
  RPC_STATUS_OK = 0
  RPC_STATUS_ERR = 1

  class << self; attr_accessor :debug; end

  # Tiny Tiny RSS JSON-RPC client
  # usage:
  #  req = RpcClient.new "http://your.host/ttr/api"
  #  rsp = req.request :Login, user: 'username', pass: 'password'
  class RpcClient

    def initialize(url)
      @uri = URI.parse url
    end

    # sends a request to the RPC server
    # - op: TTR operation
    # - args: operation arguments as a hash
    # - returns response as a hash
    def request(op, args)
      request = prepare_request op, args
      response = send_request request
      process_response op, response
    end

    private

    # combines operation and its args into a JSON request
    def prepare_request(op, args)
      request = {op: op.to_s}
      request.merge! args

      JSON.generate request
    end

    # fetches data from JSON response
    def process_response(op, rsp)
      rsp = JSON.parse rsp

      content = {}

      if rsp["content"].respond_to? :each_pair
        rsp["content"].each_pair {|k, v| content[k.to_sym] = v}
      else
        content[:data] = rsp["content"]
      end

      content[:status] = rsp["status"]
      content[:seq] = rsp["seq"]

      # specialization
      case op
      when :login
        content[:sid] = content[:session_id]
      when :isLoggedIn
        content[:logged_in] = true if content[:status] == RPC_STATUS_OK
      end

      content
    end
    
    # actually sends a request to the server
    def send_request(body)
      req = Net::HTTP::Post.new @uri.path
      req['Content-Type'] = 'application/json'
      req.body = body

      http = Net::HTTP.new @uri.host, @uri.port

      puts ">> req: #{req.body}" if Ttr.debug
      res = http.request req
      puts ">> rsp: #{res.body}" if Ttr.debug

      res.body
    end

  end

end
