module SlackGamebot
  module Commands
    class Accept < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.team, data.channel, challenger)
        if challenge
          challenge.accept!(challenger)
          send_message_with_gif client, data.channel, "#{challenge.challenged.map(&:user_name).and} accepted #{challenge.challengers.map(&:user_name).and}'s challenge.", 'game'
          logger.info "ACCEPT: #{client.team.name} - #{challenge}"
        else
          send_message client, data.channel, 'No challenge to accept!'
          logger.info "ACCEPT: #{client.team.name} - #{data.user}, N/A"
        end
      end
    end
  end
end
