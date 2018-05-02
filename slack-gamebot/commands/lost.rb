module SlackGamebot
  module Commands
    class Lost < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'lost' do |client, data, match|
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

        challenge = ::Challenge.find_by_user(client.owner, data.channel, challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])

        if !(teammates & opponents).empty?
          client.say(channel: data.channel, text: 'You cannot lose to yourself!', gif: 'loser')
          logger.info "Cannot lose to yourself: #{client.owner} - #{match}"
        elsif opponents.any? && (challenge.nil? || (challenge.challengers != opponents && challenge.challenged != opponents))
          match = ::Match.lose!(team: client.owner, winners: opponents, losers: teammates, scores: scores)
          client.say(channel: data.channel, text: "Match has been recorded! #{match}.", gif: 'loser')
          logger.info "LOST TO: #{client.owner} - #{match}"
        elsif challenge
          challenge.lose!(challenger, scores)
          client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'loser')
          logger.info "LOST: #{client.owner} - #{challenge}"
        else
          match = ::Match.where(loser_ids: challenger.id).desc(:_id).first
          if match
            match.update_attributes!(scores: scores)
            client.say(channel: data.channel, text: "Match scores have been updated! #{match}.", gif: 'score')
            logger.info "SCORED: #{client.owner} - #{match}"
          else
            client.say(channel: data.channel, text: 'No challenge to lose!')
            logger.info "LOST: #{client.owner} - #{data.user}, N/A"
          end
        end
      end
    end
  end
end
