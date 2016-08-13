module SlackGamebot
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Premium

      class << self
        def set_nickname(client, data, user, v)
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
        end

        def unset_nickname(client, data, user, v)
          target_user = user
          slack_mention = v.split.first if v
          if User.slack_mention?(slack_mention)
            fail SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
            target_user = ::User.find_by_slack_mention!(client.owner, slack_mention)
          end
          old_nickname = target_user.nickname
          premium client, data do
            target_user.update_attributes!(nickname: nil)
          end
          client.say(channel: data.channel, text: "You don't have a nickname set#{old_nickname.blank? ? '' : ' anymore'}, #{target_user.slack_mention}.", gif: 'anonymous')
          logger.info "UNSET: #{client.owner} - #{user.user_name}: nickname #{target_user == user ? '' : ' for ' + target_user.user_name} was #{old_nickname.blank? ? 'not ' : 'un'}set"
        end

        def set_gifs(client, data, user, v)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
          unless v.nil?
            premium client, data do
              client.owner.update_attributes!(gifs: v.to_b)
              client.send_gifs = client.owner.gifs
            end
          end
          client.say(channel: data.channel, text: "GIFs for team #{client.owner.name} are #{client.owner.gifs? ? 'on!' : 'off.'}", gif: 'fun')
          logger.info "SET: #{client.owner} - #{user.user_name} GIFs are #{client.owner.gifs? ? 'on' : 'off'}"
        end

        def unset_gifs(client, data, user)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
          premium client, data do
            client.owner.update_attributes!(gifs: false)
            client.send_gifs = client.owner.gifs
          end
          client.say(channel: data.channel, text: "GIFs for team #{client.owner.name} are off.", gif: 'fun')
          logger.info "UNSET: #{client.owner} - #{user.user_name} GIFs are off"
        end

        def set_unbalanced(client, data, user, v)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
          unless v.nil?
            premium client, data do
              client.owner.update_attributes!(unbalanced: v.to_b)
            end
          end
          client.say(channel: data.channel, text: "Unbalanced challenges for team #{client.owner.name} are #{client.owner.unbalanced? ? 'on!' : 'off.'}", gif: 'balance')
          logger.info "SET: #{client.owner} - #{user.user_name} unbalanced challenges are #{client.owner.unbalanced? ? 'on' : 'off'}"
        end

        def unset_unbalanced(client, data, user)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
          premium client, data do
            client.owner.update_attributes!(unbalanced: false)
          end
          client.say(channel: data.channel, text: "Unbalanced challenges for team #{client.owner.name} are off.", gif: 'balance')
          logger.info "UNSET: #{client.owner} - #{user.user_name} unbalanced challenges are off"
        end

        def set_api(client, data, user, v)
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
        end

        def unset_api(client, data, user)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
          premium client, data do
            client.owner.update_attributes!(api: false)
          end
          client.say(channel: data.channel, text: "API for team #{client.owner.name} is off.", gif: 'programmer')
          logger.info "UNSET: #{client.owner} - #{user.user_name} API is off"
        end

        def set_elo(client, data, user, v)
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
        end

        def unset_elo(client, data, user)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
          premium client, data do
            client.owner.update_attributes!(elo: 0)
          end
          client.say(channel: data.channel, text: "Base elo for team #{client.owner.name} has been unset.", gif: 'score')
          logger.info "UNSET: #{client.owner} - #{user.user_name} ELO has been unset"
        end

        def set_aliases(client, data, user, v)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?
          unless v.nil?
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
        end

        def unset_aliases(client, data, user)
          fail SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?
          premium client, data do
            client.owner.update_attributes!(aliases: [])
            client.aliases = []
          end
          client.say(channel: data.channel, text: "Team #{client.owner.name} no longer has bot aliases.", gif: 'name')
          logger.info "UNSET: #{client.owner} - #{user.user_name} no longer has bot aliases"
        end

        def set(client, data, user, k, v)
          case k
          when 'nickname' then
            set_nickname client, data, user, v
          when 'gifs' then
            set_gifs client, data, user, v
          when 'unbalanced' then
            set_unbalanced client, data, user, v
          when 'api' then
            set_api client, data, user, v
          when 'elo' then
            set_elo client, data, user, v
          when 'aliases' then
            set_aliases client, data, user, v
          else
            fail SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _elo_, _nickname_ and _aliases_."
          end
        end

        def unset(client, data, user, k, v)
          case k
          when 'nickname' then
            unset_nickname client, data, user, v
          when 'gifs' then
            unset_gifs client, data, user
          when 'unbalanced' then
            unset_unbalanced client, data, user
          when 'api' then
            unset_api client, data, user
          when 'elo' then
            unset_elo client, data, user
          when 'aliases' then
            unset_aliases client, data, user
          else
            fail SlackGamebot::Error, "Invalid setting #{k}, you can _unset gifs_, _api_, _elo_, _nickname_ and _aliases_."
          end
        end
      end

      command 'set' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, eg. _set gifs off_.', gif: 'help')
          logger.info "SET: #{client.owner} - #{user.user_name}, failed, missing setting"
        else
          k, v = match['expression'].split(/[\s]+/, 2)
          set client, data, user, k, v
        end
      end

      command 'unset' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if !match['expression']
          client.say(channel: data.channel, text: 'Missing setting, eg. _unset gifs_.', gif: 'help')
          logger.info "UNSET: #{client.owner} - #{user.user_name}, failed, missing setting"
        else
          k, v = match['expression'].split(/[\s]+/, 2)
          unset client, data, user, k, v
        end
      end
    end
  end
end
