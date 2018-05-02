module SlackGamebot
  module Commands
    class Resigned < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'resigned' do |client, data, match|
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        expression = match['expression'] if match['expression']
        arguments = expression.split.reject(&:blank?) if expression

        scores = nil
        opponents = []
        teammates = [challenger]
        multi_player = expression && expression.include?(' with ')

        current = :scores
        while arguments && arguments.any?
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
              scores << argument
            end
          end
        end

        challenge = ::Challenge.find_by_user(client.owner, data.channel, challenger, [ChallengeState::PROPOSED, ChallengeState::ACCEPTED])

        if scores && scores.any?
          client.say(channel: data.channel, text: 'Cannot score when resigning.', gif: 'idiot')
          logger.info "RESIGNED: #{client.owner} - #{data.user}, cannot score."
        elsif opponents.any? && (challenge.nil? || (challenge.challengers != opponents && challenge.challenged != opponents))
          match = ::Match.resign!(team: client.owner, winners: opponents, losers: teammates)
          client.say(channel: data.channel, text: "Match has been recorded! #{match}.", gif: 'loser')
          logger.info "RESIGNED TO: #{client.owner} - #{match}"
        elsif challenge
          challenge.resign!(challenger)
          client.say(channel: data.channel, text: "Match has been recorded! #{challenge.match}.", gif: 'loser')
          logger.info "RESIGNED: #{client.owner} - #{challenge}"
        else
          client.say(channel: data.channel, text: 'No challenge to resign!')
          logger.info "RESIGNED: #{client.owner} - #{data.user}, N/A"
        end
      end
    end
  end
end
