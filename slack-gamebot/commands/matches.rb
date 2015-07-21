module SlackGamebot
  module Commands
    class Matches < SlackRubyBot::Commands::Base
      def self.call(data, match)
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        users = arguments || []
        if arguments && arguments.any?
          users = User.find_many_by_slack_mention!(users)
        else
          users << ::User.find_create_or_update_by_slack_id!(data.user)
        end
        user_ids = users.map(&:id)
        totals = {}
        totals.default = 0
        Match.any_of({ :winner_ids.in => user_ids }, :loser_ids.in => user_ids).includes(:challenge).each do |m|
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
        send_message data.channel, message
      end
    end
  end
end
