require 'spec_helper'

describe SlackGamebot::Commands::Resigned, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:challenged) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
  before do
    challenge.accept!(challenged)
  end
  it 'resigned' do
    expect(message: "#{SlackRubyBot.config.user} resigned", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challenged.map(&:user_name).and} resigned against #{challenge.challengers.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.state).to eq ChallengeState::PLAYED
    expect(challenge.match.winners).to eq challenge.challengers
    expect(challenge.match.losers).to eq challenge.challenged
    expect(challenge.match.resigned?).to be true
  end
  it 'resigned with score' do
    expect(message: "#{SlackRubyBot.config.user} resigned 15:21", user: challenged.user_id, channel: challenge.channel).to respond_with_error(
      'Cannot score when resigning.'
    )
  end
end
