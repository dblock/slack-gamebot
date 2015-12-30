require 'new_relic/agent'

RSpec.configure do |config|
  config.before :suite do
    NewRelic::Agent.manual_start
  end
  config.after :suite do
    FileUtils.rm_rf File.expand_path('log/newrelic_agent.log')
  end
end
