require 'spec_helper'

describe SlackGamebot::Commands::Cancel, vcr: { cassette_name: 'user_info' } do
  let(:challenger) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challengers: [challenger]) }
  it 'cancels a challenge' do
    expect(message: 'gamebot cancel', user: challenger.user_id).to respond_with_slack_message(
      "#{challenge.challengers.map(&:user_name).join(' and ')} canceled a challenge against #{challenge.challenged.map(&:user_name).join(' and ')}."
    )
    expect(challenge.reload.state).to eq ChallengeState::CANCELED
  end
  it 'cancels an accepted challenge' do
    challenge.accept!(challenge.challenged.first)
    expect(message: 'gamebot cancel', user: challenger.user_id).to respond_with_slack_message(
      "#{challenge.challengers.map(&:user_name).join(' and ')} canceled a challenge against #{challenge.challenged.map(&:user_name).join(' and ')}."
    )
    expect(challenge.reload.state).to eq ChallengeState::CANCELED
  end
end
