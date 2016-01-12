module SlackGamebot
  module Commands
    class Set < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match.names.include?('expression')
          client.say(channel: data.channel, text: 'Missing setting, eg. _set gifs off_.', gif: 'help')
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
            client.say(channel: data.channel, text: "GIFs for team #{client.team.name} are #{client.team.gifs? ? 'on!' : 'off.'}", gif: 'fun')
            logger.info "SET: #{client.team} - #{user.user_name} GIFs are #{client.team.gifs? ? 'on' : 'off'}"
          when 'api' then
            client.team.update_attributes!(api: v.to_b) unless v.nil?
            client.say(channel: data.channel, text: "API for team #{client.team.name} is #{client.team.api? ? 'on!' : 'off.'}", gif: 'programmer')
            logger.info "SET: #{client.team} - #{user.user_name} API is #{client.team.api? ? 'on' : 'off'}"
          when 'aliases' then
            if v == 'none'
              client.team.update_attributes!(aliases: [])
              client.aliases = []
            elsif !v.nil?
              client.team.update_attributes!(aliases: v.split(/[\s,;]+/))
              client.aliases = client.team.aliases
            end
            if client.team.aliases.any?
              client.say(channel: data.channel, text: "Bot aliases for team #{client.team.name} are #{client.team.aliases.and}.", gif: 'name')
              logger.info "SET: #{client.team} - #{user.user_name} Bot aliases are #{client.team.aliases.and}"
            else
              client.say(channel: data.channel, text: "Team #{client.team.name} does not have any bot aliases.", gif: 'name')
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
