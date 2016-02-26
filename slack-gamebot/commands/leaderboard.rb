module SlackGamebot
  module Commands
    class Leaderboard < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        max = 3
        reverse = false
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        arguments ||= []
        case arguments.first.downcase
        when 'infinity'
          max = nil
        else
          max = Integer(arguments.first)
        end if arguments.first
        reverse = true if arguments.include? 'esrever' # This is a hidden magic trick which will reverse the ranks
        ranked_players = client.owner.users.ranked
        if ranked_players.any?
          message = ranked_players.send(reverse ? :desc : :asc, :rank).limit(max).each_with_index.map do |user, index|
            "#{index + 1}. #{user}"
          end.join("\n")
          client.say(channel: data.channel, text: message)
        else
          client.say(channel: data.channel, text: "There're no ranked players.", gif: 'empty')
        end
        logger.info "LEADERBOARD #{max || '∞'}: #{client.owner} - #{data.user}"
      end
    end
  end
end
