module SlackGamebot
  module Commands
    class Season < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        if ::Season.count > 0 && !::Challenge.current.any?
          send_message_with_gif client, data.channel, 'No matches have been recorded.', 'history'
        elsif ::Challenge.current.any?
          current_season = ::Season.new
          send_message client, data.channel, current_season.to_s
        else
          send_message_with_gif client, data.channel, "There're no seasons.", %w(winter summer fall spring).sample
        end
        logger.info "SEASON: #{data.user}"
      end
    end
  end
end
