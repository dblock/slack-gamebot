module SlackGamebot
  module Commands
    class Lost < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(data.channel, challenger)
        if challenge
          challenge.lose!(challenger)
          send_message_with_gif client, data.channel, "Match has been recorded! #{challenge.match}.", 'loser'
        else
          send_message client, data.channel, 'No challenge to lose!'
        end
      end
    end
  end
end
