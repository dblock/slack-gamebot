module SlackGamebot
  module Commands
    class Rank < Base
      def self.call(data, _command, arguments)
        users = arguments
        users << data.user.user_name if arguments.empty?
        users = User.find_many_by_slack_mention!(users)
        message = User.rank_section(users).map do |user|
          "#{user.rank}. #{user}"
        end.join("\n")
        send_message data.channel, message
      end
    end
  end
end
