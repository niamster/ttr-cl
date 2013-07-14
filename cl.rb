#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require_relative 'ttr/api'

ttr_options = {}
options = {}

class OptionParser
  def usage
    puts help
    exit
  end
end

parser = OptionParser.new do |opts|
  opts.banner = "Usage: cl.rb [options]"

  opts.on("-s", "--server=url", "Tiny Tiny RSS URL") do |url|
    ttr_options[:url] = url
  end
  opts.on("-u", "--user=user", "Tiny Tiny RSS user") do |user|
    ttr_options[:user] = user
  end
  opts.on("-p", "--pass=pass", "Tiny Tiny RSS password") do |pass|
    ttr_options[:pass] = pass
  end
  opts.on("-d", "--debug", "Debug Tiny Tiny RSS API") do |debug|
    options[:debug] = debug
  end
  opts.on("", "--list-unread", "List unread articles") do |list_unread|
    options[:list_unread] = list_unread
  end
  opts.on("", "--set-unread=article_id", "Set article as unread") do |article_id|
    options[:set_unread] = article_id
  end
  opts.on("", "--set-read=article_id", "Set article as read") do |article_id|
    options[:set_read] = article_id
  end
  opts.on("", "--toggle-read=article_id", "Toggle article read state") do |article_id|
    options[:toggle_read] = article_id
  end
end
parser.parse!

parser.usage unless ttr_options[:url]
parser.usage unless ttr_options[:user]
parser.usage unless ttr_options[:pass]

ttr_options[:trust_any_certificate] = true

Ttr.debug = options[:debug]
ttrc = Ttr::Api.new ttr_options

unless ttrc.logged_in?
  ttrc.login!
  raise "Can't login" unless ttrc.logged_in?
  puts "Logged in(sid=#{ttrc.sid})"
end

puts "Version: #{ttrc.version}"
puts "Unread: #{ttrc.get_unread}"
#pp ttrc.get_feed_tree
#pp ttrc.get_counters
#pp ttrc.get_feeds Ttr::Api::CAT_ALL
#pp ttrc.get_categories
if options[:list_unread]
  ttrc.get_headlines(Ttr::Api::FEED_ALL, true).each do |f|
    puts "Article #{f['id']}:"
    puts "--------"
    pp f
    puts "--------"
    pp ttrc.get_article f['id']
    puts "--------"
  end
end

if options[:set_unread]
  pp ttrc.set_article_as_unread! options[:set_unread]
end
if options[:set_read]
  pp ttrc.set_article_as_read! options[:set_read]
end
if options[:toggle_read]
  pp ttrc.toggle_article_read_state! options[:toggle_read]
end

ttrc.logout!
