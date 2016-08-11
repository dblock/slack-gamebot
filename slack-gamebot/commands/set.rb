module SlackGamebot
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Premium

      def self.call(client, data, match)
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, eg. _set gifs off_.', gif: 'help')
          logger.info "SET: #{client.owner} - #{user.user_name}, failed, missing setting"
        else
          k, v = match['expression'].split(/[\s]+/, 2)
          case k
          when 'nickname' then
            target_user = user
            slack_mention = v.split.first if v
            if v && User.slack_mention?(slack_mention)
              fail SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
              target_user = ::User.find_by_slack_mention!(client.owner, slack_mention)
              v = v[slack_mention.length + 1..-1]
            end
            unless v.nil?
              premium client, data do
                target_user.update_attributes!(nickname: v)
              end
            end
            if target_user.nickname.blank?
              client.say(channel: data.channel, text: "You don't have a nickname set, #{target_user.user_name}.", gif: 'anonymous')
              logger.info "SET: #{client.owner} - #{user.user_name}: nickname #{target_user == user ? '' : ' for ' + target_user.user_name}is not set"
            else
              client.say(channel: data.channel, text: "Your nickname is #{v.nil? ? '' : 'now '}*#{target_user.nickname}*, #{target_user.slack_mention}.", gif: 'name')
              logger.info "SET: #{client.owner} - #{user.user_name} nickname #{target_user == user ? '' : ' for ' + target_user.user_name}is #{target_user.nickname}"
            end
          when 'gifs' then
            fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
            unless v.nil?
              premium client, data do
                client.owner.update_attributes!(gifs: v.to_b)
                client.send_gifs = client.owner.gifs
              end
            end
            client.say(channel: data.channel, text: "GIFs for team #{client.owner.name} are #{client.owner.gifs? ? 'on!' : 'off.'}", gif: 'fun')
            logger.info "SET: #{client.owner} - #{user.user_name} GIFs are #{client.owner.gifs? ? 'on' : 'off'}"
          when 'api' then
            fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
            unless v.nil?
              premium client, data do
                client.owner.update_attributes!(api: v.to_b)
              end
            end
            message = [
              "API for team #{client.owner.name} is #{client.owner.api? ? 'on!' : 'off.'}",
              client.owner.api_url
            ].compact.join("\n")
            client.say(channel: data.channel, text: message, gif: 'programmer')
            logger.info "SET: #{client.owner} - #{user.user_name} API is #{client.owner.api? ? 'on' : 'off'}"
          when 'elo' then
            fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
            unless v.nil?
              premium client, data do
                elo = begin
                        Integer(v)
                      rescue
                        nil
                      end
                client.owner.update_attributes!(elo: elo) unless elo.nil?
              end
            end
            message = "Base elo for team #{client.owner.name} is #{client.owner.elo}."
            client.say(channel: data.channel, text: message, gif: 'score')
            logger.info "SET: #{client.owner} - #{user.user_name} ELO is #{client.owner.elo}"
          when 'aliases' then
            fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
            if v == 'none'
              premium client, data do
                client.owner.update_attributes!(aliases: [])
                client.aliases = []
              end
            elsif !v.nil?
              premium client, data do
                client.owner.update_attributes!(aliases: v.split(/[\s,;]+/))
                client.aliases = client.owner.aliases
              end
            end
            if client.owner.aliases.any?
              client.say(channel: data.channel, text: "Bot aliases for team #{client.owner.name} are #{client.owner.aliases.and}.", gif: 'name')
              logger.info "SET: #{client.owner} - #{user.user_name} Bot aliases are #{client.owner.aliases.and}"
            else
              client.say(channel: data.channel, text: "Team #{client.owner.name} does not have any bot aliases.", gif: 'name')
              logger.info "SET: #{client.owner} - #{user.user_name}, does not have any bot aliases"
            end
          else
            fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
            fail SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_, _api on|off_ and _aliases_."
          end
        end
      end
    end
  end
end
