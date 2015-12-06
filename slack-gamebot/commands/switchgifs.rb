module SlackGamebot
  module Commands
    class Switchgifs < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        if GAMEBOT_ENABLE_GIFS == true
          message = "Thanks <@#{data.user}>! Gifs are off."
          GAMEBOT_ENABLE_GIFS = false
        else
          message = "Thanks <@#{data.user}>! Gifs are on."
          GAMEBOT_ENABLE_GIFS = true
        end
        send_message_with_gif client, data.channel, message, 'welcome'
        # logger.info "DISABLEGIFS: #{data.user}"
        user
      end
    end
  end
end
