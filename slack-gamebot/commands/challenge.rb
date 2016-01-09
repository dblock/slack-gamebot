module SlackGamebot
  module Commands
    class Challenge < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        arguments ||= []
        challenge = ::Challenge.create_from_teammates_and_opponents!(client.team, data.channel, challenger, arguments)
        client.say(channel: data.channel, text: "#{challenge.challengers.map(&:user_name).and} challenged #{challenge.challenged.map(&:user_name).and} to a match!", gif: 'challenge')
        logger.info "CHALLENGE: #{client.team} - #{challenge}"
      end
    end
  end
end
