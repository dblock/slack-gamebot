$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'rspec'

require 'config/environment'
require 'slack-gamebot'

Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each do |file|
  require file
end

require 'fabrication'
require 'faker'
