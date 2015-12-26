module SlackGamebot
  module Commands
    class Promote < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        users = User.find_many_by_slack_mention!(client.team, arguments) if arguments && arguments.any?
        captains = users.select(&:captain) if users
        if !users
          send_message_with_gif client, data.channel, 'Try _promote @someone_.', 'help'
          logger.info "PROMOTE: #{client.team} - #{user.user_name}, failed, no users"
        elsif !user.captain?
          send_message_with_gif client, data.channel, "You're not a captain, sorry.", 'sorry'
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoting #{users.map(&:user_name).and}, failed, not captain"
        elsif captains && captains.count > 1
          send_message client, data.channel, "#{captains.map(&:user_name).and} are already captains."
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoting #{users.map(&:user_name).and}, failed, #{captains.map(&:user_name).and} already captains"
        elsif captains && captains.count == 1
          send_message client, data.channel, "#{captains.first.user_name} is already a captain."
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoting #{users.map(&:user_name).and}, failed, #{captains.first.user_name} already captain"
        else
          users.each(&:promote!)
          send_message_with_gif client, data.channel, "#{users.map(&:user_name).and} #{users.count == 1 ? 'has' : 'have'} been promoted to captain.", 'power'
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoted #{users.map(&:user_name).and}"
        end
      end
    end
  end
end
