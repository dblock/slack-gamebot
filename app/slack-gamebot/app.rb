module SlackGamebot
  class App
    cattr_accessor :hooks

    include SlackGamebot::Hooks::UserChange
    include SlackGamebot::Hooks::Hello
    include SlackGamebot::Hooks::Message

    def initialize
      SlackGamebot.configure do |config|
        config.token = ENV['SLACK_API_TOKEN'] || fail("Missing ENV['SLACK_API_TOKEN'].")
        config.secret = ENV['GAMEBOT_SECRET'] || warn("Missing ENV['GAMEBOT_SECRET'].")
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
      @client ||= begin
        client = Slack.realtime
        hooks.each do |hook|
          client.on hook do |data|
            begin
              send hook, data
            rescue StandardError => e
              logger.error e
              begin
                Slack.chat_postMessage(channel: data['channel'], text: e.message) if data.key?('channel')
              rescue
                # ignore
              end
            end
          end
        end
        client
      end
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
