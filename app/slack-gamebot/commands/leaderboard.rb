module SlackGamebot
  module Commands
    class Leaderboard < Base
      def self.call(data, _command, arguments)
        max = 3
        case arguments.first.downcase
        when 'infinity'
          max = nil
        else
          max = Integer(arguments.first)
        end if arguments.any?
        send_message data.channel, User.leaderboard(max)
      end
    end
  end
end
