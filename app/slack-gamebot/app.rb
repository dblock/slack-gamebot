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

    def self.instance
      @instance ||= SlackGamebot::App.new
    end

    def run
      auth!
      start!
    end

    private

    def logger
      @logger ||= begin
        $stdout.sync = true
        Logger.new(STDOUT)
      end
    end

    def start!
      client.start
    end

    def client
      @client ||= Slack.realtime.tap do |client|
        client.on :hello do |_data|
          logger.info "Successfully connected to #{SlackGamebot.config.url}."
        end
        client.on :message do |data|
          begin
            dispatch(data)
          rescue StandardError => e
            logger.error e
          end
        end
      end
    end

    def dispatch(data)
      data = Hashie::Mash.new(data)
      return unless data.text && data.text.start_with?('gamebot')
      case data.text
      when 'gamebot hi'
        message data.channel, "Hi <@#{data.user}>!"
      when /^gamebot/
        message data.channel, "Sorry <@#{data.user}>, I don't understand that command!"
      end
    end

    def message(channel, text)
      Slack.chat_postMessage(channel: channel, text: text)
    end

    def auth!
      auth = Slack.auth_test
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
