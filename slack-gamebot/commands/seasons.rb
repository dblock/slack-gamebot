module SlackGamebot
  module Commands
    class Seasons < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        current_season = ::Season.new(team: client.team)
        if current_season.valid?
          message = [current_season, client.team.seasons.desc(:_id)].flatten.map(&:to_s).join("\n")
          send_message client, data.channel, message
        elsif ::Season.where(team: client.team).any? # don't use client.team.seasons, would include current_season
          message = client.team.seasons.desc(:_id).map(&:to_s).join("\n")
          send_message client, data.channel, message
        else
          send_message_with_gif client, data.channel, "There're no seasons.", %w(winter summer fall spring).sample
        end
        logger.info "SEASONS: #{data.user}"
      end
    end
  end
end
