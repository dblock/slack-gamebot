module SlackGamebot
  module Commands
    class Taunt < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        taunter = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'] ? match['expression'].split.reject(&:blank?) : []
        if taunter.registered?
          if arguments.empty?
            client.say(channel: data.channel, text: 'Please provide a user name to taunt.')
          else
            victim = ::User.find_many_by_slack_mention!(client.owner, arguments)
            taunt = "#{victim.map(&:user_name).and} #{victim.count == 1 ? 'sucks' : 'suck'} at #{client.owner.game.name}!"
            client.say(channel: data.channel, text: "#{taunter.user_name} says that #{taunt}")
            logger.info "TAUNT: #{client.owner} - #{taunter.user_name}"
          end
        else
          client.say(channel: data.channel, text: "You aren't registered to play, please _register_ first.", gif: 'register')
          logger.info "TAUNT: #{client.owner} - #{taunter.user_name}, failed, not registered"
        end
      end
    end
  end
end
