module SlackGamebot
  module Commands
    class Leaderboard < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'leaderboard' do |client, data, match|
        max = 3
        reverse = false
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        arguments ||= []
        number = arguments.shift
        if number
          if number[0] == '-'
            reverse = true
            number = number[1..-1]
          end
          max = case number.downcase
                when 'infinity'
                  nil
                else
                  Integer(number)
                end
        end
        ranked_players = client.owner.users.ranked
        if ranked_players.any?
          message = ranked_players.send(reverse ? :desc : :asc, :rank).limit(max).each_with_index.map do |user, index|
            "#{reverse ? index + 1 : user.rank}. #{user}"
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
