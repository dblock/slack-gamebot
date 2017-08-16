module SlackGamebot
  module Commands
    class Taunt < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        taunter = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if taunter.registered?
          arguments = match['expression'].split.reject(&:blank?) if match['expression']
          arguments ||= []
          taunt = ::Taunt.create_from_teammates_and_opponents!(client.owner, data.channel, taunter, arguments)
          client.say(channel: data.channel, text: "#{taunt.taunters.map(&:user_name).and} said #{taunt.map(&:user_name).and} sucks at ping pong!")
          logger.info "TAUNT: #{client.owner} - #{taunter.user_name}"
        else
          client.say(channel: data.channel, text: "You aren't registered to play, please _register_ first.", gif: 'register')
          logger.info "TAUNT: #{client.owner} - #{taunter.user_name}, failed, not registered"

        end
      end
    end
  end
end
