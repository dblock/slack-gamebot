module SlackGamebot
  module Commands
    class Resigned < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.team, data.channel, challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])
        scores = Score.parse(match['expression']) if match.names.include?('expression')
        if challenge
          challenge.resign!(challenger, scores)
          send_message_with_gif client, data.channel, "Match has been recorded! #{challenge.match}.", 'coward'
          logger.info "RESIGNED: #{client.team} - #{challenge}"
        else
          send_message client, data.channel, 'No challenge to resign!'
          logger.info "RESIGNED: #{client.team} - #{data.user}, N/A"
        end
      end
    end
  end
end
