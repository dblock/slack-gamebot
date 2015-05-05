module SlackGamebot
  module Commands
    class Decline < Base
      def self.call(data, _command, _arguments)
        challenger = ::User.find_create_or_update_by_slack_id!(data.user)
        challenge = ::Challenge.find_by_user(challenger)
        if challenge
          challenge.decline!(challenger)
          send_message_with_gif data.channel, "#{challenge.challenged.map(&:user_name).join(' and ')} declined #{challenge.challengers.map(&:user_name).join(' and ')} challenge.", 'no'
        else
          send_message data.channel, 'No challenge to decline!'
        end
      end
    end
  end
end
