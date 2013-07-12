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

  ##### responce classes

  # basic responce class
  class Response
    attr_accessor :status, :seq, :content, :error

    def initialize(rsp)
      @rsp = rsp

      @status = @rsp["status"]
      @seq = @rsp["seq"]
      @content = @rsp["content"]
      @error = @rsp["content"]["error"] if @status == API_STATUS_ERR
    end
  end

  class ResponseGetLevel < Response
    attr_accessor :level

    def initialize(rsp)
      super

      @level = @content["level"]
    end
  end

  class ResponseGetVersion < Response
    attr_accessor :version

    def initialize(rsp)
      super

      @version = @content["version"]
    end
  end

  class ResponseIsLoggedIn < Response
    attr_accessor :logged_in

    def initialize(rsp)
      super

      @logged_in = @content["status"]
    end
  end

  class ResponseLogin < Response
    attr_accessor :sid

    def initialize(rsp)
      super

      @sid = @content["session_id"]
    end
  end

  class ResponseGetFeedTree < Response
    attr_accessor :categories

    def initialize(rsp)
      super

      @categories = @content["categories"]
    end
  end

  ##### end of responce classes

  ##### request classes

  # basic request class
  class Request
    attr_accessor :request

    def initialize(op)
      @request = {op: op}
    end

    def to_hash
      @request
    end
  end

  class Login < Request
    def initialize(user, pass)
      super "login"

      @request[:user] = user
      @request[:password] = pass
    end
  end

  class LoggedIn < Request
    def initialize(op, sid)
      super op

      @request[:sid] = sid
    end
  end

  class Logout < LoggedIn
    def initialize(sid)
      super "logout", sid
    end
  end

  class GetVersion < LoggedIn
    def initialize(sid)
      super "getVersion", sid
    end
  end

  class IsLoggedIn < LoggedIn
    def initialize(sid)
      super "isLoggedIn", sid
    end
  end

  class GetFeedTree < LoggedIn
    def initialize(sid, include_empty)
      super "getFeedTree", sid

      @request[:include_empty] = include_empty
    end
  end

  ##### end of request classes

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
      @pass = info[:pass]

      @sid = nil
    end

    def logout
      @rpc.request Logout.new @sid
    end

    def login
      rsp = @rpc.request Login.new @user, @pass
      @sid = ResponseLogin.new(rsp).sid
    end

    def logged_in?
      return false unless @sid
      rsp = @rpc.request IsLoggedIn.new @sid
      ResponseIsLoggedIn.new(rsp).logged_in
    end

    def version
      rsp = @rpc.request GetVersion.new @sid
      ResponseGetVersion.new(rsp).version
    end

    def get_feed_tree include_empty=false
      rsp = @rpc.request GetFeedTree.new @sid, include_empty
      ResponseGetFeedTree.new(rsp).categories
    end
  end

end
