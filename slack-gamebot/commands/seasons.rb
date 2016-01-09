module SlackGamebot
  module Commands
    class Seasons < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        current_season = ::Season.new(team: client.team)
        if current_season.valid?
          message = [current_season, client.team.seasons.desc(:_id)].flatten.map(&:to_s).join("\n")
          client.say(channel: data.channel, text: message)
        elsif ::Season.where(team: client.team).any? # don't use client.team.seasons, would include current_season
          message = client.team.seasons.desc(:_id).map(&:to_s).join("\n")
          client.say(channel: data.channel, text: message)
        else
          client.say(channel: data.channel, text: "There're no seasons.", gif: %w(winter summer fall spring).sample)
        end
        logger.info "SEASONS: #{client.team} - #{data.user}"
      end
    end
  end
end
