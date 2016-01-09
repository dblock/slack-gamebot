module SlackGamebot
  module Commands
    class Decline < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.team, data.channel, challenger)
        if challenge
          challenge.decline!(challenger)
          client.say(channel: data.channel, text: "#{challenge.challenged.map(&:user_name).and} declined #{challenge.challengers.map(&:user_name).and} challenge.", gif: 'no')
          logger.info "DECLINE: #{client.team} - #{challenge}"
        else
          client.say(channel: data.channel, text: 'No challenge to decline!')
          logger.info "DECLINE: #{client.team} - #{data.user}, N/A"
        end
      end
    end
  end
end
