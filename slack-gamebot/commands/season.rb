module SlackGamebot
  module Commands
    class Season < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'season' do |client, data, _match|
        if client.owner.matches.current.any? || client.owner.challenges.current.any?
          current_season = ::Season.new(team: client.owner)
          client.say(channel: data.channel, text: current_season.to_s)
        elsif client.owner.seasons.count > 0
          client.say(channel: data.channel, text: 'No matches have been recorded.', gif: 'history')
        else
          client.say(channel: data.channel, text: "There're no seasons.", gif: %w[winter summer fall spring].sample)
        end
        logger.info "SEASON: #{client.owner} - #{data.user}"
      end
    end
  end
end
