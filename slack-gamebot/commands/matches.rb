module SlackGamebot
  module Commands
    class Matches < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        totals = {}
        totals.default = 0
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        users = ::User.find_many_by_slack_mention!(arguments) if arguments && arguments.any?
        user_ids = users.map(&:id) if users && users.any?
        matches = user_ids && user_ids.any? ? ::Match.any_of({ :winner_ids.in => user_ids }, :loser_ids.in => user_ids) : ::Match.all
        matches = matches.where(:challenge_id.in => ::Challenge.current.pluck(:_id))
        matches.includes(:challenge).each do |m|
          next if m.challenge.season_id
          totals[m.to_s] += 1
        end
        message = totals.sort_by { |_, value| -value }.map do |s, count|
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
        logger.info "MATCHES: #{data.user}"
      end
    end
  end
end
