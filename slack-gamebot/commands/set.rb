module SlackGamebot
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      class << self
        def set_nickname(client, data, user, v)
          target_user = user
          slack_mention = v.split.first if v
          if v && User.slack_mention?(slack_mention)
            raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

            target_user = ::User.find_by_slack_mention!(client, slack_mention)
            v = v[slack_mention.length + 1..-1]
          end
          target_user.update_attributes!(nickname: v) unless v.nil?
          if target_user.nickname.blank?
            client.say(channel: data.channel, text: "You don't have a nickname set, #{target_user.user_name}.", gif: 'anonymous')
            logger.info "SET: #{client.owner} - #{user.user_name}: nickname #{' for ' + target_user.user_name unless target_user == user}is not set"
          else
            client.say(channel: data.channel, text: "Your nickname is #{'now ' unless v.nil?}*#{target_user.nickname}*, #{target_user.slack_mention}.", gif: 'name')
            logger.info "SET: #{client.owner} - #{user.user_name} nickname #{' for ' + target_user.user_name unless target_user == user}is #{target_user.nickname}"
          end
        end

        def unset_nickname(client, data, user, v)
          target_user = user
          slack_mention = v.split.first if v
          if User.slack_mention?(slack_mention)
            raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

            target_user = ::User.find_by_slack_mention!(client, slack_mention)
          end
          old_nickname = target_user.nickname
          target_user.update_attributes!(nickname: nil)
          client.say(channel: data.channel, text: "You don't have a nickname set#{' anymore' unless old_nickname.blank?}, #{target_user.slack_mention}.", gif: 'anonymous')
          logger.info "UNSET: #{client.owner} - #{user.user_name}: nickname #{' for ' + target_user.user_name unless target_user == user} was #{old_nickname.blank? ? 'not ' : 'un'}set"
        end

        def set_gifs(client, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          unless v.nil?
            client.owner.update_attributes!(gifs: v.to_b)
            client.send_gifs = client.owner.gifs
          end
          client.say(channel: data.channel, text: "GIFs for team #{client.owner.name} are #{client.owner.gifs? ? 'on!' : 'off.'}", gif: 'fun')
          logger.info "SET: #{client.owner} - #{user.user_name} GIFs are #{client.owner.gifs? ? 'on' : 'off'}"
        end

        def unset_gifs(client, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          client.owner.update_attributes!(gifs: false)
          client.send_gifs = client.owner.gifs
          client.say(channel: data.channel, text: "GIFs for team #{client.owner.name} are off.", gif: 'fun')
          logger.info "UNSET: #{client.owner} - #{user.user_name} GIFs are off"
        end

        def set_unbalanced(client, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          client.owner.update_attributes!(unbalanced: v.to_b) unless v.nil?
          client.say(channel: data.channel, text: "Unbalanced challenges for team #{client.owner.name} are #{client.owner.unbalanced? ? 'on!' : 'off.'}", gif: 'balance')
          logger.info "SET: #{client.owner} - #{user.user_name} unbalanced challenges are #{client.owner.unbalanced? ? 'on' : 'off'}"
        end

        def unset_unbalanced(client, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          client.owner.update_attributes!(unbalanced: false)
          client.say(channel: data.channel, text: "Unbalanced challenges for team #{client.owner.name} are off.", gif: 'balance')
          logger.info "UNSET: #{client.owner} - #{user.user_name} unbalanced challenges are off"
        end

        def set_api(client, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          client.owner.update_attributes!(api: v.to_b) unless v.nil?
          message = [
            "API for team #{client.owner.name} is #{client.owner.api? ? 'on!' : 'off.'}",
            client.owner.api_url
          ].compact.join("\n")
          client.say(channel: data.channel, text: message, gif: 'programmer')
          logger.info "SET: #{client.owner} - #{user.user_name} API is #{client.owner.api? ? 'on' : 'off'}"
        end

        def unset_api(client, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          client.owner.update_attributes!(api: false)
          client.say(channel: data.channel, text: "API for team #{client.owner.name} is off.", gif: 'programmer')
          logger.info "UNSET: #{client.owner} - #{user.user_name} API is off"
        end

        def set_elo(client, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          client.owner.update_attributes!(elo: parse_int(v)) unless v.nil?
          message = "Base elo for team #{client.owner.name} is #{client.owner.elo}."
          client.say(channel: data.channel, text: message, gif: 'score')
          logger.info "SET: #{client.owner} - #{user.user_name} ELO is #{client.owner.elo}"
        end

        def unset_elo(client, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          client.owner.update_attributes!(elo: 0)
          client.say(channel: data.channel, text: "Base elo for team #{client.owner.name} has been unset.", gif: 'score')
          logger.info "UNSET: #{client.owner} - #{user.user_name} ELO has been unset"
        end

        def set_leaderboard_max(client, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          unless v.nil?
            v = parse_int_with_inifinity(v)
            client.owner.update_attributes!(leaderboard_max: v && v != 0 ? v : nil)
          end
          message = "Leaderboard max for team #{client.owner.name} is #{client.owner.leaderboard_max || 'not set'}."
          client.say(channel: data.channel, text: message, gif: 'count')
          logger.info "SET: #{client.owner} - #{user.user_name} LEADERBOARD MAX is #{client.owner.leaderboard_max}"
        end

        def unset_leaderboard_max(client, data, user)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          client.owner.update_attributes!(leaderboard_max: nil)
          client.say(channel: data.channel, text: "Leaderboard max for team #{client.owner.name} has been unset.", gif: 'score')
          logger.info "UNSET: #{client.owner} - #{user.user_name} LEADERBOARD MAX has been unset"
        end

        def set_aliases(client, data, user, v)
          raise SlackGamebot::Error, "You're not a captain, sorry." unless v.nil? || user.captain?

          unless v.nil?
            client.owner.update_attributes!(aliases: v.split(/[\s,;]+/))
            client.aliases = client.owner.aliases
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
          raise SlackGamebot::Error, "You're not a captain, sorry." unless user.captain?

          client.owner.update_attributes!(aliases: [])
          client.aliases = []
          client.say(channel: data.channel, text: "Team #{client.owner.name} no longer has bot aliases.", gif: 'name')
          logger.info "UNSET: #{client.owner} - #{user.user_name} no longer has bot aliases"
        end

        def parse_int_with_inifinity(v)
          v == 'infinity' ? nil : parse_int(v)
        end

        def parse_int(v)
          Integer(v)
        rescue StandardError
          raise SlackGamebot::Error, "Sorry, #{v} is not a valid number."
        end

        def set(client, data, user, k, v)
          case k
          when 'nickname'
            set_nickname client, data, user, v
          when 'gifs'
            set_gifs client, data, user, v
          when 'leaderboard'
            k, v = v.split(/\s+/, 2) if v
            case k
            when 'max'
              set_leaderboard_max client, data, user, v
            else
              raise SlackGamebot::Error, "Invalid leaderboard setting #{k}, you can _set leaderboard max_."
            end
          when 'unbalanced'
            set_unbalanced client, data, user, v
          when 'api'
            set_api client, data, user, v
          when 'elo'
            set_elo client, data, user, v
          when 'aliases'
            set_aliases client, data, user, v
          else
            raise SlackGamebot::Error, "Invalid setting #{k}, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _leaderboard max_, _elo_, _nickname_ and _aliases_."
          end
        end

        def unset(client, data, user, k, v)
          case k
          when 'nickname'
            unset_nickname client, data, user, v
          when 'gifs'
            unset_gifs client, data, user
          when 'leaderboard'
            case v
            when 'max'
              unset_leaderboard_max client, data, user
            else
              raise SlackGamebot::Error, "Invalid leaderboard setting #{v}, you can _unset leaderboard max_."
            end
          when 'unbalanced'
            unset_unbalanced client, data, user
          when 'api'
            unset_api client, data, user
          when 'elo'
            unset_elo client, data, user
          when 'aliases'
            unset_aliases client, data, user
          else
            raise SlackGamebot::Error, "Invalid setting #{k}, you can _unset gifs_, _api_, _leaderboard max_, _elo_, _nickname_ and _aliases_."
          end
        end
      end

      subscribed_command 'set' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if match['expression']
          k, v = match['expression'].split(/\s+/, 2)
          set client, data, user, k, v
        else
          client.say(channel: data.channel, text: 'Missing setting, eg. _set gifs off_.', gif: 'help')
          logger.info "SET: #{client.owner} - #{user.user_name}, failed, missing setting"
        end
      end

      subscribed_command 'unset' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        if match['expression']
          k, v = match['expression'].split(/\s+/, 2)
          unset client, data, user, k, v
        else
          client.say(channel: data.channel, text: 'Missing setting, eg. _unset gifs_.', gif: 'help')
          logger.info "UNSET: #{client.owner} - #{user.user_name}, failed, missing setting"
        end
      end
    end
  end
end
