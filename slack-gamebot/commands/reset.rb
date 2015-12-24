module SlackGamebot
  module Commands
    class Reset < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !user.captain?
          send_message_with_gif client, data.channel, "You're not a captain, sorry.", 'sorry'
          logger.info "RESET: #{client.team.name} - #{user.user_name}, failed, not captain"
        elsif !match.names.include?('expression') || match['expression'] != user.team.name
          send_message_with_gif client, data.channel, "Invalid team name, confirm with _reset #{user.team.name}_.", 'help'
          logger.info "RESET: #{client.team.name} - #{user.user_name}, failed, invalid team name"
        else
          ::Season.create!(team: user.team, created_by: user)
          send_message_with_gif client, data.channel, 'Welcome to the new season!', 'season'
          logger.info "RESET: #{client.team.name} - #{data.user}"
        end
      end
    end
  end
end
