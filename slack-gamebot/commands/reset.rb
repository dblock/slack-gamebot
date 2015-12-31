module SlackGamebot
  module Commands
    class Reset < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !user.captain?
          send_message_with_gif client, data.channel, "You're not a captain, sorry.", 'sorry'
          logger.info "RESET: #{client.team} - #{user.user_name}, failed, not captain"
        elsif !match.names.include?('expression')
          send_message_with_gif client, data.channel, "Missing team name, confirm with _reset #{user.team.team_id}_.", 'help'
          logger.info "RESET: #{client.team} - #{user.user_name}, failed, missing team name"
        elsif match['expression'] != user.team.name && match['expression'] != user.team.team_id
          send_message_with_gif client, data.channel, "Invalid team name, confirm with _reset #{user.team.team_id}_.", 'help'
          logger.info "RESET: #{client.team} - #{user.user_name}, failed, invalid team name '#{match['expression']}'"
        else
          ::Season.create!(team: user.team, created_by: user)
          send_message_with_gif client, data.channel, 'Welcome to the new season!', 'season'
          logger.info "RESET: #{client.team} - #{data.user}"
        end
      end
    end
  end
end
