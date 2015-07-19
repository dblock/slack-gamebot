require 'spec_helper'

describe SlackGamebot::Commands::Lost, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::App.new }
  let(:challenged) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
  before do
    challenge.accept!(challenged)
  end
  it 'lost' do
    expect(message: "#{SlackRubyBot.config.user} lost", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challengers.map(&:user_name).join(' and ')} defeated #{challenge.challenged.map(&:user_name).join(' and ')}."
    )
    challenge.reload
    expect(challenge.state).to eq ChallengeState::PLAYED
    expect(challenge.match.winners).to eq challenge.challengers
    expect(challenge.match.losers).to eq challenge.challenged
  end
end
