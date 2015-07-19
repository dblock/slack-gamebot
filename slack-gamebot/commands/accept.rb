module SlackGamebot
  module Commands
    class Accept < SlackRubyBot::Commands::Base
      def self.call(data, _match)
        challenger = ::User.find_create_or_update_by_slack_id!(data.user)
        challenge = ::Challenge.find_by_user(data.channel, challenger)
        if challenge
          challenge.accept!(challenger)
          send_message_with_gif data.channel, "#{challenge.challenged.map(&:user_name).join(' and ')} accepted #{challenge.challengers.map(&:user_name).join(' and ')}'s challenge.", 'game'
        else
          send_message data.channel, 'No challenge to accept!'
        end
      end
    end
  end
end
