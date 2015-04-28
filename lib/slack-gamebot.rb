require 'slack-gamebot/version'
require 'slack-gamebot/config'

module SlackGamebot
  class << self
    def configure
      block_given? ? yield(Config) : Config
    end

    def config
      Config
    end
  end
end
