module SlackGamebot
  module Commands
    class Challenge < SlackRubyBot::Commands::Base
      def self.call(data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(data.user)
        arguments = match['expression'].split.reject(&:blank?) if match.names.include?('expression')
        arguments ||= []
        challenge = ::Challenge.create_from_teammates_and_opponents!(data.channel, challenger, arguments)
        send_message_with_gif data.channel, "#{challenge.challengers.map(&:user_name).join(' and ')} challenged #{challenge.challenged.map(&:user_name).join(' and ')} to a match!", 'challenge'
      end
    end
  end
end
