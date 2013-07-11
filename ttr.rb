require "thread"
require 'net/http'
require "json"

API_STATUS_OK = 0
API_STATUS_ERR = 1

module Ttr
  class << self; attr_accessor :debug; end

  # sends a request to JSON-RPC server
  # usage:
  #  req = RpcReq.new "http://your.host/ttr/api"
  #  rsp = req.request {:op => "login"}
  class RpcReq
    def initialize url
      @uri = URI.parse url
    end

    # accepts a request in hash
    # returns response in hash
    def request body
      http = Net::HTTP.new(@uri.host, @uri.port)

      req = Net::HTTP::Post.new(@uri.path, initheader = {'Content-Type' =>'application/json'})
      req.body = JSON.generate body.to_hash


      puts ">> req: #{req.body}" if Ttr.debug
      res = http.request(req)

      puts ">> rsp: #{res.body}" if Ttr.debug
      JSON.parse res.body
    end
  end

  ##### responce classes

  # basic responce class
  class Rsp
    attr_accessor :status, :seq, :content, :error

    def initialize rsp
      @rsp = rsp

      @status = @rsp["status"]
      @seq = @rsp["seq"]
      @content = @rsp["content"]
      @error = @rsp["content"]["error"] if @status == API_STATUS_ERR
    end
  end

  class RspGetLevel < Rsp
    attr_accessor :level

    def initialize rsp
      super rsp

      @level = @content["level"]
    end
  end

  class RspGetVersion < Rsp
    attr_accessor :version

    def initialize rsp
      super rsp

      @version = @content["version"]
    end
  end

  class RspIsLoggedIn < Rsp
    attr_accessor :logged_in

    def initialize rsp
      super rsp

      @logged_in = @content["status"]
    end
  end

  class RspLogin < Rsp
    attr_accessor :sid

    def initialize rsp
      super rsp

      @sid = @content["session_id"]
    end
  end

  class RspGetFeedTree < Rsp
    attr_accessor :categories

    def initialize rsp
      super rsp

      @categories = @content["categories"]
    end
  end

  ##### end of responce classes

  ##### request classes

  # basic request class
  class Req
    attr_accessor :request

    def initialize op
      @request = {:op => op}
    end

    def to_hash
      @request
    end
  end

  class Login < Req
    def initialize user, pass
      super "login"

      @request[:user] = user
      @request[:password] = pass
    end
  end

  class LoggedIn < Req
    def initialize op, sid
      super op

      @request[:sid] = sid
    end
  end

  class Logout < LoggedIn
    def initialize sid
      super "logout", sid
    end
  end

  class GetVersion < LoggedIn
    def initialize sid
      super "getVersion", sid
    end
  end

  class IsLoggedIn < LoggedIn
    def initialize sid
      super "isLoggedIn", sid
    end
  end

  class GetFeedTree < LoggedIn
    def initialize sid, include_empty
      super "getFeedTree", sid

      @request[:include_empty] = include_empty
    end
  end

  ##### end of request classes

  # represent Tiny Tiny RSS client
  # usage:
  #  req = {:url => 'http://your.host/ttr/api', :user => 'username', :pass => 'password'}
  #  ttr = Ttr::Client.new options
  #  ttr.login
  # puts ttrc.version
  class Client
    attr_accessor :sid

    def initialize info
      @rpc = RpcReq.new info[:url]
      @user = info[:user]
      @pass = info[:pass]

      @sid = nil
    end

    def logout
      @rpc.request Logout.new @sid
    end

    def login
      rsp = @rpc.request Login.new @user, @pass
      @sid = RspLogin.new(rsp).sid
    end

    def logged_in?
      return false unless @sid
      rsp = @rpc.request IsLoggedIn.new @sid
      RspIsLoggedIn.new(rsp).logged_in
    end

    def version
      rsp = @rpc.request GetVersion.new @sid
      RspGetVersion.new(rsp).version
    end

    def get_feed_tree include_empty=false
      rsp = @rpc.request GetFeedTree.new @sid, include_empty
      RspGetFeedTree.new(rsp).categories
    end
  end

end
