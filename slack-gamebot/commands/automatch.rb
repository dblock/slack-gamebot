module SlackGamebot
  module Commands
    class Automatch < SlackRubyBot::Commands::Base
      def self.call(client, data, match)
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)

        case match['expression']
        when 'on'
          challenger.automatch_time = 5.minutes.from_now
        when 'off'
          challenger.automatch_time = nil
        when nil
          if challenger.automatch_time && challenger.automatch_time > Time.now
            challenger.automatch_time = nil
          else
            challenger.automatch_time = 5.minutes.from_now
          end
        else
          fail "Invalid automatch argument #{match['expression']}"
        end

        challenger.save!

        if challenger.automatch_time
          state = 'on'
          gif_word = 'ready'
        else
          state = 'off'
          gif_word = 'gone'
        end

        logger.info "AUTOMATCH: #{client.owner} - #{challenger.user_name}: #{state}"

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
          client.say(channel: data.channel, text: "Automatch is #{state} for #{challenger.user_name} (#{automatch_users.count} users ready to play!)", gif: gif_word)
        end
      end
    end
  end
end
