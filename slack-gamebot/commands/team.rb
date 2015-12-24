module SlackGamebot
  module Commands
    class Team < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        ::User.find_create_or_update_by_slack_id!(client, data.user)
        captains = if client.team.captains.count == 1
                     ", captain #{client.team.captains.first.user_name}"
                   elsif client.team.captains.count > 1
                     ", captains #{client.team.captains.map(&:user_name).and}"
        end
        send_message_with_gif client, data.channel, "Team _#{client.team.name}_#{captains}.", 'team'
        logger.info "TEAM: #{client.team.name} - #{data.user}"
      end
    end
  end
end
