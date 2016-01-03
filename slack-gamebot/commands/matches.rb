module SlackGamebot
  module Commands
    class Matches < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        totals = {}
        totals.default = 0
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        # limit
        max = 10
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
        end if arguments && arguments.any?
        # users
        team = client.team
        users = ::User.find_many_by_slack_mention!(team, arguments) if arguments && arguments.any?
        user_ids = users.map(&:id) if users && users.any?
        matches = user_ids && user_ids.any? ? team.matches.any_of({ :winner_ids.in => user_ids }, :loser_ids.in => user_ids) : team.matches
        matches = matches.where(:challenge_id.in => team.challenges.current.pluck(:_id))
        matches.includes(:challenge).each do |m|
          next if m.challenge.season_id
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
        send_message client, data.channel, message
        logger.info "MATCHES: #{team} - #{data.user}"
      end
    end
  end
end
