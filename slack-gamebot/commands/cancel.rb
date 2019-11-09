module SlackGamebot
  module Commands
    class Cancel < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'cancel' do |client, data, _match|
        player = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.owner, data.channel, player)
        if challenge
          challenge.cancel!(player)
          if challenge.challengers.include?(player)
            client.say(channel: data.channel, text: "#{challenge.challengers.map(&:display_name).and} canceled a challenge against #{challenge.challenged.map(&:display_name).and}.", gif: 'chicken')
          elsif challenge.challenged.include?(player)
            client.say(channel: data.channel, text: "#{challenge.challenged.map(&:display_name).and} canceled a challenge against #{challenge.challengers.map(&:display_name).and}.", gif: 'chicken')
          else
            client.say(channel: data.channel, text: "#{player.display_name} canceled #{challenge}.", gif: 'chicken')
          end
          logger.info "CANCEL: #{client.owner} - #{challenge}"
        else
          client.say(channel: data.channel, text: 'No challenge to cancel!')
          logger.info "CANCEL: #{client.owner} -  #{data.user}, N/A"
        end
      end
    end
  end
end
