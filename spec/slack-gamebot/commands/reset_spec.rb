require 'spec_helper'

describe SlackGamebot::Commands::Reset, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'team' do
    let!(:team) { Fabricate(:team) }
    it 'is a premium feature' do
      expect(message: "#{SlackRubyBot.config.user} reset", user: 'user').to respond_with_slack_message(
        "This is a premium feature. Upgrade your team to premium for $29.99 a year at https://www.playplay.io/upgrade?team_id=#{team.team_id}&game=#{team.game.name}."
      )
    end
  end
  context 'premium team' do
    let!(:team) { Fabricate(:team, premium: true) }
    it 'requires a captain' do
      Fabricate(:user, captain: true, team: team)
      Fabricate(:user, user_name: 'username')
      expect(::User).to_not receive(:reset_all!).with(team)
      expect(message: "#{SlackRubyBot.config.user} reset").to respond_with_slack_message("You're not a captain, sorry.")
    end
    it 'requires a team name' do
      expect(::User).to_not receive(:reset_all!).with(team)
      expect(message: "#{SlackRubyBot.config.user} reset").to respond_with_slack_message("Missing team name or id, confirm with _reset #{team.name}_ or _reset #{team.team_id}_.")
    end
    it 'requires a matching team name' do
      expect(::User).to_not receive(:reset_all!).with(team)
      expect(message: "#{SlackRubyBot.config.user} reset invalid").to respond_with_slack_message("Invalid team name or id, confirm with _reset #{team.name}_ or _reset #{team.team_id}_.")
    end
    it 'resets with the correct team name' do
      Fabricate(:match)
      expect(::User).to receive(:reset_all!).with(team).once
      expect(message: "#{SlackRubyBot.config.user} reset #{team.name}").to respond_with_slack_message('Welcome to the new season!')
    end
    it 'resets with the correct team id' do
      Fabricate(:match)
      expect(::User).to receive(:reset_all!).with(team).once
      expect(message: "#{SlackRubyBot.config.user} reset #{team.team_id}").to respond_with_slack_message('Welcome to the new season!')
    end
    it 'resets a team that has a period and space in the name' do
      team.update_attributes!(name: 'Pets.com Delivery')
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
    it 'resets user stats for the right team' do
      Fabricate(:match)
      user1 = Fabricate(:user, elo: 48, losses: 1, wins: 2, tau: 0.5, ties: 3)
      team2 = Fabricate(:team)
      Fabricate(:match, team: team2)
      user2 = Fabricate(:user, team: team2, elo: 48, losses: 1, wins: 2, tau: 0.5, ties: 3)
      expect(message: "#{SlackRubyBot.config.user} reset #{team.name}").to respond_with_slack_message('Welcome to the new season!')
      user1.reload
      expect(user1.wins).to eq 0
      expect(user1.losses).to eq 0
      expect(user1.tau).to eq 0
      expect(user1.elo).to eq 0
      expect(user1.ties).to eq 0
      user2.reload
      expect(user2.wins).to eq 2
      expect(user2.losses).to eq 1
      expect(user2.tau).to eq 0.5
      expect(user2.elo).to eq 48
      expect(user2.ties).to eq 3
    end
  end
end
