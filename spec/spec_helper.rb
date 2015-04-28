$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'slack-gamebot'

SlackGamebot.configure do |_config|
  # TODO
end
