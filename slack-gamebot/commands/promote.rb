module SlackGamebot
  module Commands
    class Promote < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        users = User.find_many_by_slack_mention!(client.team, arguments) if arguments && arguments.any?
        captains = users.select(&:captain) if users
        if !users
          client.say(channel: data.channel, text: 'Try _promote @someone_.', gif: 'help')
          logger.info "PROMOTE: #{client.team} - #{user.user_name}, failed, no users"
        elsif !user.captain?
          client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoting #{users.map(&:user_name).and}, failed, not captain"
        elsif captains && captains.count > 1
          client.say(channel: data.channel, text: "#{captains.map(&:user_name).and} are already captains.")
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoting #{users.map(&:user_name).and}, failed, #{captains.map(&:user_name).and} already captains"
        elsif captains && captains.count == 1
          client.say(channel: data.channel, text: "#{captains.first.user_name} is already a captain.")
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoting #{users.map(&:user_name).and}, failed, #{captains.first.user_name} already captain"
        else
          users.each(&:promote!)
          client.say(channel: data.channel, text: "#{users.map(&:user_name).and} #{users.count == 1 ? 'has' : 'have'} been promoted to captain.", gif: 'power')
          logger.info "PROMOTE: #{client.team} - #{user.user_name} promoted #{users.map(&:user_name).and}"
        end
      end
    end
  end
end
