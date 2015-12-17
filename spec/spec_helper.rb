$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'fabrication'
require 'faker'
require 'hyperclient'

ENV['RACK_ENV'] = 'test'

require 'slack-ruby-bot/rspec'
require 'slack-gamebot'

Dir[File.join(File.dirname(__FILE__), 'support', '**/*.rb')].each do |file|
  require file
end
