require 'spec_helper'

describe SlackGamebot::Commands::Decline, vcr: { cassette_name: 'user_info' } do
  let(:challenged) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
  it 'declines a challenge' do
    expect(message: 'gamebot decline', user: challenged.user_id).to respond_with_slack_message(
      "#{challenge.challenged.map(&:user_name).join(' and ')} declined #{challenge.challengers.map(&:user_name).join(' and ')} challenge."
    )
    expect(challenge.reload.state).to eq ChallengeState::DECLINED
  end
end
