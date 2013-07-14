require_relative "rpc"

module Ttr
  # represents a Tiny Tiny RSS API
  # usage:
  #  options = {url: 'http://your.host/ttr/api', user: 'username', pass: 'password'}
  #  ttr = Ttr::Api.new options
  #  puts ttr.version
  class Api
    CAT_UNCATEGORIZED = 0
    CAT_SPECIAL = -1
    CAT_LABELS = -2
    CAT_ALL_BUT_VIRTUAL = -3
    CAT_ALL = -4

    FEED_ARCHIVED = 0
    FEED_STARRED = -1
    FEED_PUBLISHED = -2
    FEED_FRESH = -3
    FEED_ALL = -4

    ARTICLE_FIELD_STARRED = 0
    ARTICLE_FIELD_PUBLISHED = 1
    ARTICLE_FIELD_UNREAD = 2

    ARTICLE_FIELD_ACTION_UNSET = 0
    ARTICLE_FIELD_ACTION_SET = 1
    ARTICLE_FIELD_ACTION_TOGGLE = 2
    
    attr_accessor :sid

    def initialize(info)
      @rpc = RpcClient.new info[:url]

      @user = info[:user]
      @password = info[:pass]

      @sid = nil
    end

    def request(op, args={})
      args = args.merge(sid: @sid) unless op == :login
      @rpc.request op, args
    end
    private :request

    def logout!
      request :logout
      @sid = nil
    end

    def login!
      content = request :login, user: @user, password: @password
      @sid = content[:sid]
    end

    def logged_in?
      return false unless @sid

      content = request :isLoggedIn
      content[:logged_in]
    end

    def version
      content = request :getVersion
      content[:version]
    end

    def get_feed_tree(include_empty=false)
      content = request :getFeedTree, include_empty: include_empty
      content[:categories]
    end

    def get_feeds(cat_id, unread_only=false, limit=-1)
      args = {cat_id: cat_id,
        unread_only: unread_only}
      args[:limit] = limit if limit > 0

      content = request :getFeeds, args
      data = []
      content[:data].each do |d|
        next if d['id'].to_i <= 0

        data << d
      end
    end

    def get_categories(include_empty=false, unread_only=false)
      args = {include_empty: include_empty,
        unread_only: unread_only}

      content = request :getCategories, args
      data = []
      content[:data].each do |d|
        d['id'] = d['id'].to_i

        data << d
      end
    end

    def get_headlines(feed_id, unread_only=false, limit=-1)
      args = {feed_id: feed_id}
      args[:limit] = limit if limit > 0
      args[:view_mode] = 'unread' if unread_only

      content = request :getHeadlines, args
      content[:data]
    end

    def get_article(article_id)
      content = request :getArticle, {article_id: article_id}
      content[:data]
    end

    def get_unread
      content = request :getUnread
      content[:unread].to_i
    end

    def get_counters(output_mode='flc')
      content = request :getCounters, output_mode: output_mode

      data = []
      content[:data].each do |d|
        next if d['id'].to_s !~ /-?\d+/

        data << {id: d['id'].to_i, counter: d['counter'].to_i}
      end
    end

    def subscribe_to_feed!(url, cat_id=0, login=nil, password=nil)
      args = {feed_url: url,
        category_id: cat_id}
      args[:login] = login if login
      args[:password] = password if password

      content = request :subscribeToFeed, args
      content[:status] == RPC_STATUS_OK
    end

    def usubscribe_feed!(feed_id)
      content = request :unsubscribeFeed, feed_id: feed_id
      content[:status] == RPC_STATUS_OK
    end

    def update_article!(article_id, field, action)
      args = {article_ids: article_id,
        mode: action,
        field: field}
      content = request :updateArticle, args
      content[:status] == RPC_STATUS_OK \
        && content[:updated] == 1
    end

    def set_article_as_unread!(article_id)
      update_article! article_id, \
        ARTICLE_FIELD_UNREAD, \
        ARTICLE_FIELD_ACTION_SET
    end

    def set_article_as_read!(article_id)
      update_article! article_id, \
        ARTICLE_FIELD_UNREAD, \
        ARTICLE_FIELD_ACTION_UNSET
    end

    def toggle_article_read_state!(article_id)
      update_article! article_id, \
        ARTICLE_FIELD_UNREAD, \
        ARTICLE_FIELD_ACTION_TOGGLE
    end

  end

end
