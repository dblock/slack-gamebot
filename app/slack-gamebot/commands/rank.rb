module SlackGamebot
  module Commands
    class Rank < Base
      def self.call(data, _command, arguments)
        users = arguments
        if arguments.any?
          users = User.find_many_by_slack_mention!(users)
        else
          users << ::User.find_create_or_update_by_slack_id!(data.user)
        end
        message = User.rank_section(users).map do |user|
          user.rank ? "#{user.rank}. #{user}" : "#{user.user_name}: not ranked"
        end.join("\n")
        send_message data.channel, message
      end
    end
  end
end
