module SlackGamebot
  module Commands
    class Challenge < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'challenge' do |client, data, match|
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        arguments ||= []
        challenge = ::Challenge.create_from_teammates_and_opponents!(client, data.channel, challenger, arguments)
        client.say(channel: data.channel, text: "#{challenge.challengers.map(&:slack_mention).and} challenged #{challenge.challenged.map(&:slack_mention).and} to a match!", gif: 'challenge')
        logger.info "CHALLENGE: #{client.owner} - #{challenge}"
      end
    end
  end
end
