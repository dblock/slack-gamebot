$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'slack-gamebot'

Thread.new do
  begin
    SlackGamebot::App.instance.run
  rescue Exception => e
    STDERR.puts e
    STDERR.puts e.backtrace
    raise e
  end
end

run Api::Middleware.instance
