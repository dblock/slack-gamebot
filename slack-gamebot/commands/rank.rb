module SlackGamebot
  module Commands
    class Rank < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        users = arguments || []
        if arguments && arguments.any?
          users = User.find_many_by_slack_mention!(users)
        else
          users << ::User.find_create_or_update_by_slack_id!(client, data.user)
        end
        message = User.rank_section(users).map do |user|
          user.rank ? "#{user.rank}. #{user}" : "#{user.user_name}: not ranked"
        end.join("\n")
        send_message client, data.channel, message
        logger.info "RANK: #{users.map(&:user_name).join(', ')}"
      end
    end
  end
end
