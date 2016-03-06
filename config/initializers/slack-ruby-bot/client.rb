module SlackRubyBot
  class Client < Slack::RealTime::Client
    # keep track of the team that the client is connected to
    attr_accessor :owner
  end
end

Slack::RealTime::Client.configure do |config|
  config.store_class = Slack::RealTime::Stores::Starter
end
