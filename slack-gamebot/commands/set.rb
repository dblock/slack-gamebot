module SlackGamebot
  module Commands
    class Set < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match.names.include?('expression')
          send_message_with_gif client, data.channel, 'Missing setting, eg. _set gifs off_.', 'help'
          logger.info "SET: #{client.team} - #{user.user_name}, failed, missing setting"
        else
          k, v = match['expression'].split(/\W+/, 2)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
          case k
          when 'gifs' then
            unless v.nil?
              client.team.update_attributes!(gifs: v.to_b)
              client.send_gifs = client.team.gifs
            end
            send_message_with_gif client, data.channel, "GIFs for team #{client.team.name} are #{client.team.gifs? ? 'on!' : 'off.'}", 'fun'
            logger.info "SET: #{client.team} - #{user.user_name} GIFs are #{client.team.gifs? ? 'on' : 'off'}"
          when 'aliases' then
            if v == 'none'
              client.team.update_attributes!(aliases: [])
              client.aliases = []
            elsif !v.nil?
              client.team.update_attributes!(aliases: v.split(/[\s,;]+/))
              client.aliases = client.team.aliases
            end
            if client.team.aliases.any?
              send_message_with_gif client, data.channel, "Bot aliases for team #{client.team.name} are #{client.team.aliases.and}.", 'name'
              logger.info "SET: #{client.team} - #{user.user_name} Bot aliases are #{client.team.aliases.and}"
            else
              send_message_with_gif client, data.channel, "Team #{client.team.name} does not have any bot aliases.", 'name'
              logger.info "SET: #{client.team} - #{user.user_name}, does not have any bot aliases"
            end
          else
            fail SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_ and _aliases_."
          end
        end
      end
    end
  end
end
