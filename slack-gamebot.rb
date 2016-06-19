ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

Dir[File.expand_path('../config/initializers', __FILE__) + '/**/*.rb'].each do |file|
  require file
end

Mongoid.load! File.expand_path('../config/mongoid.yml', __FILE__), ENV['RACK_ENV']

require 'slack-gamebot/error'
require 'slack-gamebot/version'
require 'slack-gamebot/info'
require 'slack-gamebot/models'
require 'slack-gamebot/api'
require 'slack-gamebot/app'
require 'slack-gamebot/server'
require 'slack-gamebot/service'
require 'slack-gamebot/commands'
