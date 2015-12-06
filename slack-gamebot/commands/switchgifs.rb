module SlackGamebot
  module Commands
    class Switchgifs < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        if :enable_gifs == true
          message = "Thanks <@#{data.user}>! Gifs are off."
          :enable_gifs = false
        else
          message = "Thanks <@#{data.user}>! Gifs are on."
          :enable_gifs = true
        end
        send_message_with_gif client, data.channel, message, 'welcome'
        # logger.info "DISABLEGIFS: #{data.user}"
        user
      end
    end
  end
end
