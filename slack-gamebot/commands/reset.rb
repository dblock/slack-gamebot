module SlackGamebot
  module Commands
    class Reset < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        fail ArgumentError, "Missing ENV['GAMEBOT_SECRET']." unless SlackGamebot.config.secret.present?
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        secret = arguments.first if arguments
        fail ArgumentError, 'Missing secret.' unless secret.present?
        fail ArgumentError, 'Invalid secret.' unless secret == SlackGamebot.config.secret
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        ::Season.create!(created_by: user)
        send_message_with_gif client, data.channel, 'Welcome to the new season!', 'season'
        logger.info "RESET: #{data.user}"
      end
    end
  end
end
