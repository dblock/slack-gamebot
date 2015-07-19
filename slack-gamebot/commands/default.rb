module SlackGamebot
  module Commands
    class Default < SlackRubyBot::Commands::Base
      match(/^(?<bot>\w*)$/)

      def self.call(data, _match)
        send_message data.channel, SlackGamebot::ASCII
      end
    end
  end
end
