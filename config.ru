require File.expand_path('../app', __FILE__)

Thread.new do
  SlackGamebot::App.instance.run
end

run Api::Middleware.instance
