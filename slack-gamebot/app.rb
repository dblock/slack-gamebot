module SlackGamebot
  class App < SlackRubyBot::App
    include SlackGamebot::Hooks::UserChange

    def initialize
      silence_loggers!
      configure!
      check_mongodb_provider!
      check_database!
      super
    end

    def self.instance
      @instance ||= SlackGamebot::App.new
    end

    private

    def silence_loggers!
      Mongoid.logger.level = Logger::INFO
      Mongo::Logger.logger.level = Logger::INFO
    end

    def configure!
      SlackGamebot.configure do |config|
        config.secret = ENV['GAMEBOT_SECRET'] || warn("Missing ENV['GAMEBOT_SECRET'].")
      end
    end

    def check_mongodb_provider!
      return unless ENV['RACK_ENV'] == 'production'
      fail "Missing ENV['MONGOHQ_URI'] or ENV['MONGOLAB_URI']." unless ENV['MONGOHQ_URI'] || ENV['MONGOLAB_URI']
    end

    def check_database!
      rc = Mongoid.default_client.command(ping: 1)
      return if rc && rc.ok?
      fail rc.documents.first['error'] || 'Unexpected error.'
    rescue Exception => e
      warn "Error connecting to MongoDB: #{e.message}"
      raise e
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
