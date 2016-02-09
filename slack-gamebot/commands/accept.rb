module SlackGamebot
  module Commands
    class Accept < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.owner, data.channel, challenger)
        if challenge
          challenge.accept!(challenger)
          client.say(channel: data.channel, text: "#{challenge.challenged.map(&:user_name).and} accepted #{challenge.challengers.map(&:user_name).and}'s challenge.", gif: 'game')
          logger.info "ACCEPT: #{client.owner} - #{challenge}"
        else
          client.say(channel: data.channel, text: 'No challenge to accept!')
          logger.info "ACCEPT: #{client.owner} - #{data.user}, N/A"
        end
      end
    end
  end
end
