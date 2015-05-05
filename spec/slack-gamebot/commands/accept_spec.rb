require 'spec_helper'

describe SlackGamebot::Commands::Accept, vcr: { cassette_name: 'user_info' } do
  let(:challenged) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
  it 'accepts a challenge' do
    expect(message: 'gamebot accept', user: challenged.user_id).to respond_with_slack_message(
      "#{challenge.challenged.map(&:user_name).join(' and ')} accepted #{challenge.challengers.map(&:user_name).join(' and ')} challenge."
    )
    expect(challenge.reload.state).to eq ChallengeState::ACCEPTED
  end
end
