module SlackGamebot
  module Commands
    class Set < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match.names.include?('expression')
          send_message_with_gif client, data.channel, 'Missing setting, eg. _set gifs off_.', 'help'
          logger.info "SET: #{client.team} - #{user.user_name}, failed, missing setting"
        else
          k, v = match['expression'].split(/\W/, 2)
          case k
          when 'gifs'
            unless v.nil?
              if !user.captain?
                send_message_with_gif client, data.channel, "You're not a captain, sorry.", 'sorry'
                logger.info "SET: #{client.team} - #{user.user_name}, failed, not captain"
              else
                client.team.update_attributes!(gifs: v.to_b)
                client.send_gifs = client.team.gifs
              end
            end
            if v.nil? || user.captain?
              send_message_with_gif client, data.channel, "GIFs for team #{client.team.name} are #{client.team.gifs? ? 'on!' : 'off.'}", 'fun'
              logger.info "SET: #{client.team} - #{user.user_name} GIFs are #{client.team.gifs? ? 'on' : 'off'}."
            end
          else
            send_message_with_gif client, data.channel, "Invalid setting #{k}, you can _set gifs on|off_.", 'help'
            logger.info "SET: #{client.team} - #{user.user_name}, failed, invalid setting #{k}"
          end
        end
      end
    end
  end
end
