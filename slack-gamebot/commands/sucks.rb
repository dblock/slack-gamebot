module SlackGamebot
  module Commands
    class Sucks < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'sucks', 'suck', 'you suck', 'sucks!', 'you suck!' do |client, data, _match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if user.losses && user.losses > 5
          client.say(channel: data.channel, text: "No <@#{data.user}>, with #{user.losses} losses, you suck!", gif: 'loser')
        elsif user.rank && user.rank > 3
          client.say(channel: data.channel, text: "No <@#{data.user}>, with a rank of #{user.rank}, you suck!", gif: 'loser')
        else
          client.say(channel: data.channel, text: "No <@#{data.user}>, you suck!", gif: 'rude')
        end
        logger.info "SUCKS: #{client.owner} - #{data.user}"
      end
    end
  end
end
