require "thread"
require 'net/http'
require "json"

module Ttr
  API_STATUS_OK = 0
  API_STATUS_ERR = 1

  class << self; attr_accessor :debug; end

  # sends a request to JSON-RPC server
  # usage:
  #  req = RPCRequest.new "http://your.host/ttr/api"
  #  rsp = req.request {op: "login"}
  class RPCRequest
    def initialize(url)
      @uri = URI.parse url
    end

    # accepts a request in hash
    # returns response in hash
    def request(body)
      http = Net::HTTP.new(@uri.host, @uri.port)

      req = Net::HTTP::Post.new(@uri.path, initheader = {'Content-Type' => 'application/json'})
      req.body = JSON.generate body.to_hash


      puts ">> req: #{req.body}" if Ttr.debug
      res = http.request(req)

      puts ">> rsp: #{res.body}" if Ttr.debug
      JSON.parse res.body
    end
  end

  ##### response interface
  class Response
    attr_accessor :status, :seq, :content, :error

    def response_attr_accessor(*args)
      args.each do |arg|
        attr = arg.to_s
        eval("def self.#{attr};@#{attr};end")
        eval("def self.#{attr}=(val);@#{attr}=val;end")
      end
    end

    def initialize(req, rsp)
      @rsp = rsp

      @status = @rsp["status"]
      @seq = @rsp["seq"]
      @content = @rsp["content"]
      @error = @rsp["content"]["error"] if @status == API_STATUS_ERR

      # specialization
      case req.op
        when :GetVersion
        @version = @content["version"]
        response_attr_accessor :version if @version
      when :GetLevel
        @version = @content["level"]
        response_attr_accessor :level if @level
      when :Login
        @sid = @content["session_id"]
        response_attr_accessor :sid if @sid
      when :GetFeedTree
        @categories = @content["categories"]
        response_attr_accessor :categories if @categories
      when :IsLoggedIn
        @logged_in = @content["status"]
        response_attr_accessor :logged_in if @status
      end
    end
  end

  ##### request interface
  class Request
    attr_accessor :request, :op

    def initialize(op, args)
      @op = op
      @request = {op: op.to_s}
      @request.merge! args
    end

    def to_hash
      @request
    end
  end

  # represent Tiny Tiny RSS client
  # usage:
  #  req = {url: 'http://your.host/ttr/api', user: 'username', pass: 'password'}
  #  ttr = Ttr::Client.new options
  #  ttr.login
  # puts ttrc.version
  class Client
    attr_accessor :sid

    def initialize(info)
      @rpc = RPCRequest.new info[:url]
      @user = info[:user]
      @password = info[:pass]

      @sid = nil
    end

    def logout
      @rpc.request Request.new :Logout, {sid: @sid}
    end

    def login
      req = Request.new :Login, {user: @user, password: @password}
      rsp = @rpc.request req
      @sid = Response.new(req, rsp).sid
    end

    def logged_in?
      return false unless @sid
      req = Request.new :IsLoggedIn, {sid: @sid}
      rsp = @rpc.request req
      Response.new(req, rsp).logged_in
    end

    def version
      req = Request.new :GetVersion, {sid: @sid}
      rsp = @rpc.request req
      Response.new(req, rsp).version
    end

    def get_feed_tree include_empty=false
      req = Request.new :GetFeedTree, {sid: @sid, include_empty: include_empty}
      rsp = @rpc.request req
      Response.new(req, rsp).categories
    end
  end

end
