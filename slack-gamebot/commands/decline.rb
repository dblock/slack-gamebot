module SlackGamebot
  module Commands
    class Decline < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(data.channel, challenger)
        if challenge
          challenge.decline!(challenger)
          send_message_with_gif client, data.channel, "#{challenge.challenged.map(&:user_name).join(' and ')} declined #{challenge.challengers.map(&:user_name).join(' and ')} challenge.", 'no'
          logger.info "DECLINE: #{challenge}"
        else
          send_message client, data.channel, 'No challenge to decline!'
          logger.info "DECLINE: #{data.user}, N/A"
        end
      end
    end
  end
end
