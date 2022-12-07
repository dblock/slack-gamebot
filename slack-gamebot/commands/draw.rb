module SlackGamebot
  module Commands
    class Draw < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'draw' do |client, data, match|
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        expression = match['expression'] if match['expression']
        arguments = expression.split.reject(&:blank?) if expression

        scores = nil
        opponents = []
        teammates = [challenger]
        multi_player = expression&.include?(' with ')

        current = :scores
        while arguments&.any?
          argument = arguments.shift
          case argument
          when 'to' then
            current = :opponents
          when 'with' then
            current = :teammates
          else
            if current == :opponents
              opponents << ::User.find_by_slack_mention!(client, argument)
              current = :scores unless multi_player
            elsif current == :teammates
              teammates << ::User.find_by_slack_mention!(client, argument)
              current = :scores if opponents.count == teammates.count
            else
              scores ||= []
              scores << Score.check(argument)
            end
          end
        end

        challenge = ::Challenge.find_by_user(client.owner, data.channel, challenger, [
                                               ChallengeState::PROPOSED,
                                               ChallengeState::ACCEPTED,
                                               ChallengeState::DRAWN
                                             ])

        if !(teammates & opponents).empty?
          client.say(channel: data.channel, text: 'You cannot draw to yourself!', gif: 'loser')
          logger.info "Cannot draw to yourself: #{client.owner} - #{match}"
        elsif opponents.any? && (challenge.nil? || (challenge.challengers != opponents && challenge.challenged != opponents))
          challenge = ::Challenge.create!(
            team: client.owner, channel: data.channel,
            created_by: challenger, updated_by: challenger,
            challengers: teammates, challenged: opponents,
            draw: [challenger], draw_scores: scores,
            state: ChallengeState::DRAWN
          )
          messages = [
            "Match is a draw, waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:display_name).and}.",
            challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
          ].compact
          client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
          logger.info "DRAW TO: #{client.owner} - #{challenge}"
        elsif challenge
          if challenge.draw.include?(challenger)
            challenge.update_attributes!(draw_scores: scores) if scores
            messages = [
              "Match is a draw, still waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:display_name).and}.",
              challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
            ].compact
            client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
          else
            challenge.draw!(challenger, scores)
            if challenge.state == ChallengeState::PLAYED
              client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'tie')
            else
              messages = [
                "Match is a draw, waiting to hear from #{(challenge.challengers + challenge.challenged - challenge.draw).map(&:display_name).and}.",
                challenge.draw_scores? ? "Recorded #{Score.scores_to_string(challenge.draw_scores)}." : nil
              ].compact
              client.say(channel: data.channel, text: messages.join(' '), gif: 'tie')
            end
          end
          logger.info "DRAW: #{client.owner} - #{challenge}"
        else
          match = ::Match.any_of({ winner_ids: challenger.id }, loser_ids: challenger.id).desc(:id).first
          if match&.tied?
            match.update_attributes!(scores:)
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
