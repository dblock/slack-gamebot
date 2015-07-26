module SlackGamebot
  module Commands
    class Season < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        current_season = ::Season.new
        if current_season.valid?
          send_message client, data.channel, current_season.to_s
        else
          send_message_with_gif client, data.channel, "There're no seasons.", %w(winter summer fall spring).sample
        end
      end
    end
  end
end
