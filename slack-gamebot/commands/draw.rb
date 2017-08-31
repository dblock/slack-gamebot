module SlackGamebot
  module Commands
    class Draw < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.owner, data.channel, challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])
        scores = Score.parse(match['expression']) if match['expression']
        if scores && scores.any? && Stripe.api_key && !client.owner.reload.premium
          client.say channel: data.channel, text: "Recording scores is now a premium feature, sorry. #{client.owner.upgrade_text}"
          logger.info "#{client.owner}, user=#{data.user}, text=#{data.text}, recording scores is now a premium feature"
        elsif challenge
          if challenge.draw.include?(challenger)
            challenge.update_attributes!(draw_scores: scores) if scores
            messages = [
              "Match is a draw, still waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:user_name).and}.",
              challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
            ].compact
            client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
          else
            challenge.draw!(challenger, scores)
            if challenge.state == ChallengeState::PLAYED
              client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'tie')
            else
              messages = [
                "Match is a draw, waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:user_name).and}.",
                challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
              ].compact
              client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
            end
          end
          logger.info "DRAW: #{client.owner} - #{challenge}"
        else
          match = ::Match.any_of({ winner_ids: challenger.id }, loser_ids: challenger.id).desc(:id).first
          if match && match.tied?
            match.update_attributes!(scores: scores)
            client.say(channel: data.channel, text: "Match scores have been updated! #{match}.", gif: 'score')
            logger.info "SCORED: #{client.owner} - #{match}"
          else
            client.say(channel: data.channel, text: 'No challenge to draw!')
            logger.info "DRAW: #{client.owner} - #{data.user}, N/A"
          end
        end
      end
    end
  end
end
