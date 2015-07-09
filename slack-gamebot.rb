ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

Dir[File.expand_path('../config/initializers', __FILE__) + '/**/*.rb'].each do |file|
  require file
end

Mongoid.load! File.expand_path('../config/mongoid.yml', __FILE__), ENV['RACK_ENV']

require 'slack-ruby-bot'
require 'slack-gamebot/hooks'
require 'slack-gamebot/version'
require 'slack-gamebot/ascii'
require 'slack-gamebot/models'
require 'slack-gamebot/api'
require 'slack-gamebot/app'
require 'slack-gamebot/config'
require 'slack-gamebot/commands'
