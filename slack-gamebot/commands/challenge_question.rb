module SlackGamebot
  module Commands
    class ChallengeQuestion < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'challenge?' do |client, data, match|
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        arguments ||= []
        challenge = ::Challenge.new_from_teammates_and_opponents(client, data.channel, challenger, arguments)
        match = ::Match.new(team: client.owner, winners: challenge.challengers, losers: challenge.challenged, scores: [])
        client.say(channel: data.channel, text: "#{challenge.challengers.map(&:slack_mention).and} challenging #{challenge.challenged.map(&:slack_mention).and} to a match is worth #{match.elo_s} elo.", gif: 'challenge')
        logger.info "CHALLENGE?: #{client.owner} - #{challenge}"
      end
    end
  end
end
