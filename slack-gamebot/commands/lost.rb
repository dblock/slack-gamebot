module SlackGamebot
  module Commands
    class Lost < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(data.channel, challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED, ChallengeState::PLAYED])
        scores = Score.parse(match['expression']) if match.names.include?('expression')
        if challenge && challenge.state == ChallengeState::PLAYED && challenge.match
          challenge.match.update_attributes!(scores: scores)
          send_message_with_gif client, data.channel, "Match scores have been updated! #{challenge.match}.", 'score'
        elsif challenge
          challenge.lose!(challenger, scores)
          send_message_with_gif client, data.channel, "Match has been recorded! #{challenge.match}.", 'loser'
        else
          send_message client, data.channel, 'No challenge to lose!'
        end
      end
    end
  end
end
