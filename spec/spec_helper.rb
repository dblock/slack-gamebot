$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'rspec'

require 'config/environment'
require 'slack-gamebot'

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/slack'
  config.hook_into :webmock
  config.default_cassette_options = { record: :new_episodes }
end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
end
