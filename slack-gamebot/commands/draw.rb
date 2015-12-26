module SlackGamebot
  module Commands
    class Draw < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.team, data.channel, challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])
        if challenge
          if challenge.draw.include?(challenger)
            send_message_with_gif client, data.channel, "Match is a draw, still waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:user_name).and}.", 'tie'
          else
            challenge.draw!(challenger)
            if challenge.state == ChallengeState::PLAYED
              send_message_with_gif client, data.channel, "Match has been recorded! #{challenge.match}.", 'tie'
            else
              send_message_with_gif client, data.channel, "Match is a draw, waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:user_name).and}.", 'tie'
            end
          end
          logger.info "DRAW: #{client.team} - #{challenge}"
        else
          send_message client, data.channel, 'No challenge to draw!'
          logger.info "DRAW: #{client.team} - #{data.user}, N/A"
        end
      end
    end
  end
end
