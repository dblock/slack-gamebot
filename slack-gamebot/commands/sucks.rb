module SlackGamebot
  module Commands
    class Sucks < SlackRubyBot::Commands::Base
      match(/\bsuck\b/i)
      match(/\bsucks\b/i)

      def self.call(client, data, _match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if user.losses && user.losses > 5
          send_message_with_gif client, data.channel, "No <@#{data.user}>, with #{user.losses} losses, you suck!", 'loser'
        elsif user.rank && user.rank > 3
          send_message_with_gif client, data.channel, "No <@#{data.user}>, with a rank of #{user.rank}, you suck!", 'loser'
        else
          send_message_with_gif client, data.channel, "No <@#{data.user}>, you suck!", 'rude'
        end
        logger.info "SUCKS: #{client.team} - #{data.user}"
      end
    end
  end
end
