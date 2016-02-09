module SlackGamebot
  module Commands
    class Challenges < SlackRubyBot::Commands::Base
      def self.call(client, data, _match)
        challenges = ::Challenge.where(
          channel: data.channel,
          :state.in => [ChallengeState::PROPOSED, ChallengeState::ACCEPTED]
        ).asc(:created_at)

        if challenges.any?
          challenges_s = challenges.map do |challenge|
            "#{challenge} was #{challenge.state} #{(challenge.updated_at || challenge.created_at).ago_in_words}"
          end.join("\n")
          client.say(channel: data.channel, text: challenges_s, gif: 'memories')
        else
          client.say(channel: data.channel, text: 'All the challenges have been played.', gif: 'boring')
        end
        logger.info "CHALLENGES: #{client.owner} - #{data.user}"
      end
    end
  end
end
