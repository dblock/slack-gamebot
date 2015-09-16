module SlackGamebot
  module Commands
    class Leaderboard < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        max = 3
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        arguments ||= []
        case arguments.first.downcase
        when 'infinity'
          max = nil
        else
          max = Integer(arguments.first)
        end if arguments.any?
        message = User.ranked.asc(:rank).limit(max).map do |user|
          "#{user.rank}. #{user}"
        end.join("\n")
        send_message client, data.channel, message
        logger.info "LEADERBOARD #{max || '∞'}: #{data.user}"
      end
    end
  end
end
