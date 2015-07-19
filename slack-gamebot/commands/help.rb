module SlackGamebot
  module Commands
    class Help < SlackRubyBot::Commands::Base
      def self.call(data, _match)
        send_message_with_gif data.channel, 'See https://github.com/dblock/slack-gamebot, please.', 'help'
      end
    end
  end
end
