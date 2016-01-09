module SlackGamebot
  module Commands
    class Resigned < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.team, data.channel, challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])
        scores = Score.parse(match['expression']) if match.names.include?('expression')
        if challenge
          challenge.resign!(challenger, scores)
          client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'coward')
          logger.info "RESIGNED: #{client.team} - #{challenge}"
        else
          client.say(channel: data.channel, text: 'No challenge to resign!')
          logger.info "RESIGNED: #{client.team} - #{data.user}, N/A"
        end
      end
    end
  end
end
