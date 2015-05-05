module SlackGamebot
  module Commands
    class Cancel < Base
      def self.call(data, _command, _arguments)
        challenger = ::User.find_create_or_update_by_slack_id!(data.user)
        challenge = ::Challenge.find_by_user(challenger)
        if challenge
          challenge.cancel!(challenger)
          send_message_with_gif data.channel,  "#{challenge.challengers.map(&:user_name).join(' and ')} canceled a challenge against #{challenge.challenged.map(&:user_name).join(' and ')}.", 'chicken'
        else
          send_message data.channel, 'No challenge to cancel!'
        end
      end
    end
  end
end
