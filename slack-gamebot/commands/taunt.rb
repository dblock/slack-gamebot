module SlackGamebot
  module Commands
    class Taunt < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        taunter = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'].split.reject(&:blank?) if match['expression']
        arguments ||= []
        if arguments.length > 1
          client.say(channel: data.channel, text: 'Please only provide one user name to taunt.')
        elsif arguments.length < 1
          client.say(channel: data.channel, text: 'Please provide a user name to taunt.')
        else
          victim = ::User.find_by_slack_mention!(client.owner, arguments.first)
          if taunter.registered?
            client.say(channel: data.channel, text: "#{taunter.user_name} says that #{victim.user_name} sucks at #{client.owner.game.name}!")
            logger.info "TAUNT: #{client.owner} - #{taunter.user_name}"
          else
            client.say(channel: data.channel, text: "You aren't registered to play, please _register_ first.", gif: 'register')
            logger.info "TAUNT: #{client.owner} - #{taunter.user_name}, failed, not registered"
          end
        end
      end
    end
  end
end
