$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

require 'slack-ruby-bot-server'
require 'slack-gamebot'

if ENV['RACK_ENV'] == 'development'
  puts 'Loading NewRelic in developer mode ...'
  require 'new_relic/rack/developer_mode'
  use NewRelic::Rack::DeveloperMode
end

NewRelic::Agent.manual_start

SlackRubyBotServer.configure do |config|
  config.server_class = SlackGamebot::Server
end

SlackGamebot::App.instance.prepare!

Thread.abort_on_exception = true

Thread.new do
  SlackGamebot::Service.instance.start_from_database!
end

run Api::Middleware.instance
