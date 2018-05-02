module SlackGamebot
  module Commands
    class Team < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'team' do |client, data, _match|
        ::User.find_create_or_update_by_slack_id!(client, data.user)
        captains = if client.owner.captains.count == 1
                     ", captain #{client.owner.captains.first.user_name}"
                   elsif client.owner.captains.count > 1
                     ", captains #{client.owner.captains.map(&:user_name).and}"
        end
        client.say(channel: data.channel, text: "Team _#{client.owner.name}_ (#{client.owner.team_id})#{captains}.", gif: 'team')
        logger.info "TEAM: #{client.owner} - #{data.user}"
      end
    end
  end
end
