module SlackGamebot
  module Commands
    class Reset < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Premium

      premium_command 'reset' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !user.captain?
          client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
          logger.info "RESET: #{client.owner} - #{user.user_name}, failed, not captain"
        elsif !match['expression']
          client.say(channel: data.channel, text: "Missing team name or id, confirm with _reset #{user.team.name}_ or _reset #{user.team.team_id}_.", gif: 'help')
          logger.info "RESET: #{client.owner} - #{user.user_name}, failed, missing team name"
        elsif match['expression'] != user.team.name && match['expression'] != user.team.team_id
          client.say(channel: data.channel, text: "Invalid team name or id, confirm with _reset #{user.team.name}_ or _reset #{user.team.team_id}_.", gif: 'help')
          logger.info "RESET: #{client.owner} - #{user.user_name}, failed, invalid team name '#{match['expression']}'"
        else
          ::Season.create!(team: user.team, created_by: user)
          client.say(channel: data.channel, text: 'Welcome to the new season!', gif: 'season')
          logger.info "RESET: #{client.owner} - #{data.user}"
        end
      end
    end
  end
end
