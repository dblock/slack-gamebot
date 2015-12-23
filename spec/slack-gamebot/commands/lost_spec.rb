require 'spec_helper'

describe SlackGamebot::Commands::Lost, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:challenged) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
  before do
    challenge.accept!(challenged)
  end
  it 'lost' do
    expect(message: "#{SlackRubyBot.config.user} lost", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.state).to eq ChallengeState::PLAYED
    expect(challenge.match.winners).to eq challenge.challengers
    expect(challenge.match.losers).to eq challenge.challenged
  end
  it 'lost with score' do
    expect(message: "#{SlackRubyBot.config.user} lost 15:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.match.scores).to eq [[15, 21]]
  end
  it 'lost with invalid score' do
    expect(message: "#{SlackRubyBot.config.user} lost 21:15", user: challenged.user_id, channel: challenge.channel).to respond_with_error(
      'Loser scores must come first.'
    )
  end
  it 'lost with scores' do
    expect(message: "#{SlackRubyBot.config.user} lost 21:15 14:21 5:11", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.match.scores).to eq [[21, 15], [14, 21], [5, 11]]
  end
  it 'lost with a crushing score' do
    expect(message: "#{SlackRubyBot.config.user} lost 5:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challengers.map(&:user_name).and} crushed #{challenge.challenged.map(&:user_name).and}."
    )
  end
  it 'lost in a close game' do
    expect(message: "#{SlackRubyBot.config.user} lost 19:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge.challengers.map(&:user_name).and} narrowly defeated #{challenge.challenged.map(&:user_name).and}."
    )
  end
  it 'lost amending scores' do
    challenge.lose!(challenged)
    expect(message: "#{SlackRubyBot.config.user} lost 21:15 14:21 5:11", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match scores have been updated! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.match.scores).to eq [[21, 15], [14, 21], [5, 11]]
  end
  it 'does not update a previously lost match' do
    challenge.lose!(challenged, [[11, 21]])
    challenge2 = Fabricate(:challenge, challenged: [challenged])
    challenge2.accept!(challenged)
    expect(message: "#{SlackRubyBot.config.user} lost", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match has been recorded! #{challenge2.challengers.map(&:user_name).and} defeated #{challenge2.challenged.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.match.scores).to eq [[11, 21]]
    challenge2.reload
    expect(challenge2.state).to eq ChallengeState::PLAYED
    expect(challenge2.match.scores).to be nil
  end
  it 'does not update a previously won match' do
    challenge.lose!(challenge.challengers.first, [[11, 21]])
    expect(message: "#{SlackRubyBot.config.user} lost", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      'No challenge to lose!'
    )
  end
end
