module SlackGamebot
  module Commands
    class Seasons < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Premium

      premium_command 'seasons' do |client, data, _match|
        current_season = ::Season.new(team: client.owner)
        if current_season.valid?
          message = [current_season, client.owner.seasons.desc(:_id)].flatten.map(&:to_s).join("\n")
          client.say(channel: data.channel, text: message)
        elsif ::Season.where(team: client.owner).any? # don't use client.owner.seasons, would include current_season
          message = client.owner.seasons.desc(:_id).map(&:to_s).join("\n")
          client.say(channel: data.channel, text: message)
        else
          client.say(channel: data.channel, text: "There're no seasons.", gif: %w(winter summer fall spring).sample)
        end
        logger.info "SEASONS: #{client.owner} - #{data.user}"
      end
    end
  end
end
