module SlackGamebot
  module Commands
    class Lost < Base
      def self.call(data, _command, _arguments)
        challenger = ::User.find_create_or_update_by_slack_id!(data.user)
        challenge = ::Challenge.find_by_user(challenger)
        if challenge
          challenge.lose!(challenger)
          send_message_with_gif data.channel, "Match has been recorded! #{challenge.match}.", 'loser'
        else
          send_message data.channel, 'No challenge to lose!'
        end
      end
    end
  end
end
