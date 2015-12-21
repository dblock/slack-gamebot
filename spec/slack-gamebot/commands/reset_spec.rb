require 'spec_helper'

describe SlackGamebot::Commands::Reset, vcr: { cassette_name: 'user_info' } do
  let(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  it 'requires a captain' do
    Fabricate(:user, captain: true, team: team)
    Fabricate(:user, user_name: 'username')
    expect(::User).to_not receive(:reset_all!).with(team)
    expect(message: "#{SlackRubyBot.config.user} reset").to respond_with_slack_message("You're not a captain, sorry.")
  end
  it 'requires a team name' do
    expect(::User).to_not receive(:reset_all!).with(team)
    expect(message: "#{SlackRubyBot.config.user} reset").to respond_with_slack_message("Invalid team name, confirm with _reset #{team.name}_.")
  end
  it 'requires a matching team name' do
    expect(::User).to_not receive(:reset_all!).with(team)
    expect(message: "#{SlackRubyBot.config.user} reset invalid").to respond_with_slack_message("Invalid team name, confirm with _reset #{team.name}_.")
  end
  it 'resets with the correct team name' do
    Fabricate(:match)
    expect(::User).to receive(:reset_all!).with(team).once
    expect(message: "#{SlackRubyBot.config.user} reset #{team.name}").to respond_with_slack_message('Welcome to the new season!')
  end
  it 'cancels open challenges' do
    proposed_challenge = Fabricate(:challenge, state: ChallengeState::PROPOSED)

    accepted_challenge = Fabricate(:challenge, state: ChallengeState::PROPOSED)
    accepted_challenge.accept!(accepted_challenge.challenged.first)

    expect(message: "#{SlackRubyBot.config.user} reset #{team.name}").to respond_with_slack_message('Welcome to the new season!')

    expect(proposed_challenge.reload.state).to eq ChallengeState::CANCELED
    expect(accepted_challenge.reload.state).to eq ChallengeState::CANCELED
  end
  it 'resets user stats' do
    Fabricate(:match)
    user = Fabricate(:user, elo: 48, losses: 1, wins: 2, tau: 0.5)
    expect(message: "#{SlackRubyBot.config.user} reset #{team.name}").to respond_with_slack_message('Welcome to the new season!')
    user.reload
    expect(user.wins).to eq 0
    expect(user.losses).to eq 0
    expect(user.tau).to eq 0
    expect(user.elo).to eq 0
  end
end
