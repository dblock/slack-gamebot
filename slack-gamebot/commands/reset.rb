module SlackGamebot
  module Commands
    class Reset < SlackRubyBot::Commands::Base
      def self.call(data, _command, arguments)
        fail ArgumentError, "Missing ENV['GAMEBOT_SECRET']." unless SlackGamebot.config.secret.present?
        secret = arguments.first
        fail ArgumentError, 'Missing secret.' unless secret.present?
        fail ArgumentError, 'Invalid secret.' unless secret == SlackGamebot.config.secret
        user = ::User.find_create_or_update_by_slack_id!(data.user)
        ::Challenge.where(
          :state.in => [ChallengeState::PROPOSED, ChallengeState::ACCEPTED]
        ).set(
          state: ChallengeState::CANCELED,
          updated_by_id: user.id
        )
        send_message_with_gif data.channel, 'Welcome to the new season!', 'season'
        ::User.reset_all!
      end
    end
  end
end
