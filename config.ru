$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

require 'slack-ruby-bot-server'
require 'slack-gamebot'

NewRelic::Agent.manual_start

SlackRubyBotServer.configure do |config|
  config.server_class = SlackGamebot::Server
end

SlackGamebot::App.instance.prepare!

Thread.abort_on_exception = true

Thread.new do
  SlackGamebot::Service.instance.start_from_database!
  SlackGamebot::App.instance.after_start!
end

run Api::Middleware.instance
