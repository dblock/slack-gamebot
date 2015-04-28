require 'slack-gamebot/version'
require 'slack-gamebot/config'
require 'slack-gamebot/app'

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
