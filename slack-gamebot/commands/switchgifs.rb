module SlackGamebot
  module Commands
    class Switchgifs < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        # fail ArgumentError, "Missing ENV['GAMEBOT_SECRET']." unless SlackGamebot.config.secret.present?
        # arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        # secret = arguments.first if arguments
        # fail ArgumentError, 'Missing secret.' unless secret.present?
        # fail ArgumentError, 'Invalid secret.' unless secret == SlackGamebot.config.secret
        if SlackGamebot.config.enable_gifs == true
          message = "Thanks <@#{data.user}>! Gifs are off."
          SlackGamebot.config.enable_gifs = false
        else
          message = "Thanks <@#{data.user}>! Gifs are on."
          SlackGamebot.config.enable_gifs = true
        end
        send_message_with_gif client, data.channel, message, 'welcome'
        # logger.info "DISABLEGIFS: #{data.user}"
        user
      end
    end
  end
end
