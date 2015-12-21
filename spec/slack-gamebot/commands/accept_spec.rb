require 'spec_helper'

describe SlackGamebot::Commands::Accept, vcr: { cassette_name: 'user_info' } do
  let(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:challenged) { Fabricate(:user, team: team, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, team: team, challenged: [challenged]) }
  it 'accepts a challenge' do
    expect(message: "#{SlackRubyBot.config.user} accept", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "#{challenge.challenged.map(&:user_name).and} accepted #{challenge.challengers.map(&:user_name).and}'s challenge."
    )
    expect(challenge.reload.state).to eq ChallengeState::ACCEPTED
  end
end
