module SlackGamebot
  module Commands
    class Leaderboard < SlackRubyBot::Commands::Base
      def self.call(data, match)
        max = 3
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        arguments ||= []
        case arguments.first.downcase
        when 'infinity'
          max = nil
        else
          max = Integer(arguments.first)
        end if arguments.any?
        message = User.ranked(max).map do |user|
          "#{user.rank}. #{user}"
        end.join("\n")
        send_message data.channel, message
      end
    end
  end
end
