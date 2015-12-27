$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'slack-gamebot'

if ENV['RACK_ENV'] == 'development'
  puts 'Loading NewRelic in developer mode ...'
  require 'new_relic/rack/developer_mode'
  use NewRelic::Rack::DeveloperMode
end

NewRelic::Agent.manual_start

SlackGamebot::App.instance.prepare!

Thread.abort_on_exception = true

Thread.new do
  begin
    EM.run do
      SlackGamebot::Service.start_from_database!
    end
  rescue Exception => e
    STDERR.puts "#{e.class}: #{e}"
    STDERR.puts e.backtrace
    raise e
  end
end

run Api::Middleware.instance
