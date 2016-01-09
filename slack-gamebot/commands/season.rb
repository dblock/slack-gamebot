module SlackGamebot
  module Commands
    class Season < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        if client.team.seasons.count > 0 && !client.team.challenges.current.any?
          client.say(channel: data.channel, text: 'No matches have been recorded.', gif: 'history')
        elsif client.team.challenges.current.any?
          current_season = ::Season.new(team: client.team)
          client.say(channel: data.channel, text: current_season.to_s)
        else
          client.say(channel: data.channel, text: "There're no seasons.", gif: %w(winter summer fall spring).sample)
        end
        logger.info "SEASON: #{client.team} - #{data.user}"
      end
    end
  end
end
