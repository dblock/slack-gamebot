module SlackGamebot
  module Commands
    class Matches < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Premium

      premium_command 'matches' do |client, data, match|
        totals = {}
        totals.default = 0
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        # limit
        max = 10
        if arguments && arguments.any?
          case arguments.last.downcase
          when 'infinity'
            max = nil
          else
            begin
              Integer(arguments.last).tap do |value|
                max = value
                arguments.pop
              end
            rescue ArgumentError
            end
          end
        end
        # users
        team = client.owner
        users = ::User.find_many_by_slack_mention!(client, arguments) if arguments && arguments.any?
        user_ids = users.map(&:id) if users && users.any?
        matches = team.matches.current
        matches = matches.any_of({ :winner_ids.in => user_ids }, :loser_ids.in => user_ids) if user_ids && user_ids.any?
        matches.each do |m|
          totals[m.to_s] += 1
        end
        totals = totals.sort_by { |_, value| -value }
        totals = totals.take(max) if max
        message = totals.map do |s, count|
          case count
          when 1
            "#{s} once"
          when 2
            "#{s} twice"
          else
            "#{s} #{count} times"
          end
        end.join("\n")
        client.say(channel: data.channel, text: !message.empty? ? message : 'No matches.')
        logger.info "MATCHES: #{team} - #{data.user}"
      end
    end
  end
end
