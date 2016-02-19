module SlackGamebot
  module Commands
    class Automatch < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)

        case match['expression']
        when 'on'
          challenger.automatch = true
        when 'off'
          challenger.automatch = false
        when nil
          challenger.automatch = !challenger.automatch
        end

        challenger.save!

        if challenger.automatch
          state = 'on'
          gif_word = 'ready'
        else
          state = 'off'
          gif_word = 'leave'
        end
        client.say(channel: data.channel, text: "Automatch is #{state} for #{challenger.user_name}", gif: gif_word)
        logger.info "AUTOMATCH: #{client.owner} - #{challenger.user_name}: #{state}"
      end
    end
  end
end
