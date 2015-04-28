module SlackGamebot
  class App
    def initialize
      SlackGamebot.configure do |config|
        config.token = ENV['SLACK_API_TOKEN'] || fail("Missing ENV['SLACK_API_TOKEN'].")
      end
      Slack.configure do |config|
        config.token = SlackGamebot.config.token
      end
    end

    def config
      SlackGamebot.config
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.instance
      @instance ||= SlackGamebot::App.new
    end

    def run
      auth!
    end

    private

    def auth!
      auth = Slack.auth_test
      fail auth['error'] unless auth['ok']
      SlackGamebot.configure do |config|
        config.url = auth['url']
        config.team = auth['team']
        config.user = auth['user']
        config.team_id = auth['team_id']
        config.user_id = auth['user_id']
      end
      logger.info "Welcome '#{SlackGamebot.config.user}' to the '#{SlackGamebot.config.team}' team at #{SlackGamebot.config.url}."
    end
  end
end
