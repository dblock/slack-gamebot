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
          send_message_with_gif client, data.channel, challenges_s, 'memories'
        else
          send_message_with_gif client, data.channel, 'All the challenges have been played.', 'boring'
        end
        logger.info "CHALLENGES: #{data.user}"
      end
    end
  end
end
