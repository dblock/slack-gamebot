module SlackGamebot
  module Commands
    class Promote < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        users = User.find_many_by_slack_mention!(client.team, arguments) if arguments && arguments.any?
        admins = users.select(&:is_admin) if users
        if !users
          send_message_with_gif client, data.channel, 'Try _promote @someone_.', 'help'
          logger.info "PROMOTE: #{user.user_name}, failed, no users"
        elsif !user.is_admin?
          send_message_with_gif client, data.channel, "You're not an admin, sorry.", 'sorry'
          logger.info "PROMOTE: #{user.user_name} promoting #{users.map(&:user_name).and}, failed, not admin"
        elsif admins && admins.count > 1
          send_message client, data.channel, "#{admins.map(&:user_name).and} are already admins."
          logger.info "PROMOTE: #{user.user_name} promoting #{users.map(&:user_name).and}, failed, #{admins.map(&:user_name).and} already admins"
        elsif admins && admins.count == 1
          send_message client, data.channel, "#{admins.first.user_name} is already an admin."
          logger.info "PROMOTE: #{user.user_name} promoting #{users.map(&:user_name).and}, failed, #{admins.first.user_name} already admin"
        else
          users.each(&:promote!)
          send_message_with_gif client, data.channel, "#{users.map(&:user_name).and} #{users.count == 1 ? 'has' : 'have'} been promoted to admin.", 'power'
          logger.info "PROMOTE: #{user.user_name} promoted #{users.map(&:user_name).and}"
        end
      end
    end
  end
end
