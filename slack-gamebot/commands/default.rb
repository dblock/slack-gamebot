module SlackGamebot
  module Commands
    class Default < SlackRubyBot::Commands::Base
      def self.call(data, _command, _arguments)
        send_message data.channel, SlackGamebot::ASCII
      end
    end
  end
end
