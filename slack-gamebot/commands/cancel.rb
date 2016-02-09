module SlackGamebot
  module Commands
    class Cancel < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        player = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.owner, data.channel, player)
        if challenge
          challenge.cancel!(player)
          if challenge.challengers.include?(player)
            client.say(channel: data.channel, text: "#{challenge.challengers.map(&:user_name).and} canceled a challenge against #{challenge.challenged.map(&:user_name).and}.", gif: 'chicken')
          elsif challenge.challenged.include?(player)
            client.say(channel: data.channel, text: "#{challenge.challenged.map(&:user_name).and} canceled a challenge against #{challenge.challengers.map(&:user_name).and}.", gif: 'chicken')
          else
            client.say(channel: data.channel, text: "#{player.user_name} canceled #{challenge}.", gif: 'chicken')
          end
          logger.info "CANCEL: #{client.owner} - #{challenge}"
        else
          client.say(channel: data.channel, text: 'No challenge to cancel!')
          logger.info "CANCEL: #{client.owner} -  #{data.user}, N/A"
        end
      end
    end
  end
end
