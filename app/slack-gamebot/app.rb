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
        client.on :hello do
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
      bot_name, command = parse_command(data.text)
      case command
      when ''
        message data.channel, SlackGamebot::ASCII
      when 'hi'
        message data.channel, "Hi <@#{data.user}>!"
      else
        message data.channel, "Sorry <@#{data.user}>, I don't understand that command!"
      end if bot_name == SlackGamebot.config.user
    end

    def parse_command(text)
      parts = text.split.reject(&:blank?) if text
      bot_name = parts.first if parts
      [bot_name, parts[1..parts.length].join]
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
