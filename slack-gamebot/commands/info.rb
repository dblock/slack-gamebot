module SlackGamebot
  module Commands
    class Info < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: SlackGamebot::INFO)
        logger.info "INFO: #{client.owner} - #{data.user}"
      end
    end
  end
end
