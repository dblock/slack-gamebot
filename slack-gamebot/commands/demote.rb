module SlackGamebot
  module Commands
    class Demote < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match.names.include?('expression') || match['expression'] != 'me'
          client.say(channel: data.channel, text: 'You can only demote yourself, try _demote me_.', gif: 'help')
          logger.info "DEMOTE: #{client.team} - #{user.user_name}, failed, not me"
        elsif !user.captain?
          client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
          logger.info "DEMOTE: #{client.team} - #{user.user_name}, failed, not captain"
        elsif client.team.captains.count == 1
          client.say(channel: data.channel, text: "You cannot demote yourself, you're the last captain. Promote someone else first.", gif: 'sorry')
          logger.info "DEMOTE: #{client.team} - #{user.user_name}, failed, last captain"
        else
          user.demote!
          client.say(channel: data.channel, text: "#{user.user_name} is no longer captain.")
          logger.info "DEMOTED: #{client.team} - #{user.user_name}"
        end
      end
    end
  end
end
