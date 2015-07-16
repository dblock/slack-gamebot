module SlackGamebot
  class App < SlackRubyBot::App
    include SlackGamebot::Hooks::UserChange

    def initialize
      SlackGamebot.configure do |config|
        config.secret = ENV['GAMEBOT_SECRET'] || warn("Missing ENV['GAMEBOT_SECRET'].")
      end
      super
    end

    def self.instance
      @instance ||= SlackGamebot::App.new
    end
  end

  class << self
    def configure
      block_given? ? yield(SlackGamebot::Config) : SlackGamebot::Config
    end

    def config
      SlackGamebot::Config
    end
  end
end
