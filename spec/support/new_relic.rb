require 'new_relic/agent'

RSpec.configure do |config|
  config.before :suite do
    NewRelic::Agent.manual_start
  end
end
