module SlackGamebot
  module Commands
    class Demote < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if match['expression'] != 'me'
          send_message_with_gif client, data.channel, 'You can only demote yourself, try _demote me_.', 'help'
          logger.info "DEMOTE: #{user.user_name}, failed, not me"
        elsif !user.is_admin?
          send_message_with_gif client, data.channel, "You're not an admin, sorry.", 'sorry'
          logger.info "DEMOTE: #{user.user_name}, failed, not admin"
        elsif client.team.admins.count == 1
          send_message_with_gif client, data.channel, "You cannot demote yourself, you're the last admin. Promote someone else first.", 'sorry'
          logger.info "DEMOTE: #{user.user_name}, failed, last admin"
        else
          user.demote!
          send_message client, data.channel, "#{user.user_name} is no longer admin."
          logger.info "DEMOTED: #{user.user_name}"
        end
      end
    end
  end
end
