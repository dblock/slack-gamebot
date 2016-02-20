module SlackGamebot
  module Commands
    class Automatch < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)

        case match['expression']
        when 'on'
          challenger.automatch_time = 5.minutes.from_now
          challenger.save!
          automatch_on(challenger, client, data)
        when 'off'
          challenger.automatch_time = nil
          challenger.save!
          automatch_off(challenger, client, data)
        when /^until\b/i
          parsed_time = Chronic.parse(match['expression'].sub(/^until\W*/, ''))
          fail SlackGamebot::Error, "Can't understand time specified" unless parsed_time

          challenger.automatch_time = parsed_time
          challenger.save!
          automatch_on(challenger, client, data)
        when /^for\b/i
          parsed_time = ChronicDuration.parse(match['expression'].sub(/^for\W*/, ''))
          fail SlackGamebot::Error, "Can't understand time specified" unless parsed_time

          challenger.automatch_time = Time.now + parsed_time
          challenger.save!
          automatch_on(challenger, client, data)
        when nil
          automatch_users = User.where(:automatch_time.gt => Time.now).order(automatch_time: :asc)
          if (automatch_users.count == 0)
            client.say(channel: data.channel, text: 'No users currently have automatch turned on')
          else
            times = automatch_users.map do |user|
              duration = ChronicDuration.output((user.automatch_time - Time.new).to_i, keep_zero: true)
              "#{user.user_name} for #{duration}"
            end.join("\n")

            client.say(channel: data.channel, text: times)
          end
        else
          fail SlackGamebot::Error, "Invalid automatch argument '#{match['expression']}'"
        end
      end

      def self.automatch_on(challenger, client, data)
        logger.info "AUTOMATCH: #{client.owner} - #{challenger.user_name}: #{challenger.automatch_time}"

        automatch_users = User.where(:automatch_time.gt => Time.now).order(elo: :asc).limit(4)
        if automatch_users.count == 4
          challenge = ::Challenge.create!(
            team: client.owner,
            channel: data.channel,
            created_by: challenger,
            updated_by: automatch_users[1],
            challengers: [automatch_users[0], automatch_users[3]],
            challenged: [automatch_users[1], automatch_users[2]],
            state: ChallengeState::ACCEPTED
          )

          automatch_users.each do |user|
            user.automatch_time = nil
            user.save!
          end

          client.say(channel: data.channel, text: "Automatch: #{challenge.challengers.map(&:user_name).and} vs #{challenge.challenged.map(&:user_name).and}!", gif: 'challenge')
          logger.info "CHALLENGE: #{client.owner} - #{challenge}"
        else
          client.say(channel: data.channel, text: "Automatch is on for #{challenger.user_name} (#{automatch_users.count} users ready to play!)", gif: 'ready')
        end
      end

      def self.automatch_off(challenger, client, data)
        automatch_count = User.where(:automatch_time.gt => Time.now).count
        logger.info "AUTOMATCH: #{client.owner} - #{challenger.user_name}: OFF"

        client.say(channel: data.channel, text: "Automatch is off for #{challenger.user_name} (#{automatch_count} users ready to play!)", gif: 'leave')
      end
    end
  end
end
