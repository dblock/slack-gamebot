module SlackGamebot
  module Commands
    class Rank < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        users = arguments || []
        if arguments && arguments.any?
          users = User.find_many_by_slack_mention!(client.owner, users)
        else
          users << ::User.find_create_or_update_by_slack_id!(client, data.user)
        end
        message = User.rank_section(client.owner, users).map do |user|
          user.rank ? "#{user.rank}. #{user}" : "#{user.user_name}: not ranked"
        end.join("\n")
        client.say(channel: data.channel, text: message)
        logger.info "RANK: #{client.owner} - #{users.map(&:user_name).and}"
      end
    end
  end
end
