#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require_relative 'ttr'

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
end
parser.parse!

parser.usage unless ttr_options[:url]
parser.usage unless ttr_options[:user]
parser.usage unless ttr_options[:pass]

Ttr.debug = options[:debug]
ttrc = Ttr::Client.new ttr_options

pp ttrc.logged_in?
ttrc.login
pp ttrc.sid
pp ttrc.logged_in?
pp ttrc.version
pp ttrc.get_feed_tree
ttrc.logout
