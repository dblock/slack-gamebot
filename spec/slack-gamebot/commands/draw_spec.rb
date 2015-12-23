require 'spec_helper'

describe SlackGamebot::Commands::Draw, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:challenged) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
  before do
    challenge.accept!(challenged)
  end
  it 'draw' do
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match is a draw, waiting to hear from #{challenge.challengers.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.state).to eq ChallengeState::ACCEPTED
    expect(challenge.draw).to eq challenge.challenged
  end
  it 'draw confirmed' do
    challenge.draw!(challenge.challengers.first)
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challengers.map(&:user_name).and} tied with #{challenge.challenged.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.state).to eq ChallengeState::PLAYED
    expect(challenge.draw).to eq challenge.challenged + challenge.challengers
  end
  it 'draw already confirmed' do
    challenge.draw!(challenge.challenged.first)
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match is a draw, still waiting to hear from #{challenge.challengers.map(&:user_name).and}."
    )
  end
  it 'does not update a previously lost match' do
    challenge.lose!(challenge.challenged.first)
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      'No challenge to draw!'
    )
  end
  it 'does not update a previously won match' do
    challenge.lose!(challenge.challengers.first)
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      'No challenge to draw!'
    )
  end
end
