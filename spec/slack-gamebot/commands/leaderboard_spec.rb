require 'spec_helper'

describe SlackGamebot::Commands::Leaderboard do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  shared_examples_for 'leaderboard' do
    context 'with players' do
      let!(:user_elo_42) { Fabricate(:user, elo: 42, wins: 3, losses: 2) }
      let!(:user_elo_48) { Fabricate(:user, elo: 48, wins: 2, losses: 3) }
      it 'displays leaderboard sorted by elo' do
        expect(message: "#{SlackRubyBot.config.user} leaderboard").to respond_with_slack_message "1. #{user_elo_48}\n2. #{user_elo_42}"
      end
      it 'excludes unregistered users' do
        user_elo_48.unregister!
        expect(message: "#{SlackRubyBot.config.user} leaderboard").to respond_with_slack_message "1. #{user_elo_42}"
      end
      it 'limits to max' do
        expect(message: "#{SlackRubyBot.config.user} leaderboard 1").to respond_with_slack_message "1. #{user_elo_48}"
      end
      it 'supports infinity' do
        user_elo_43 = Fabricate(:user, elo: 43, wins: 2, losses: 3)
        user_elo_44 = Fabricate(:user, elo: 44, wins: 2, losses: 3)
        expect(message: "#{SlackRubyBot.config.user} leaderboard infinity").to respond_with_slack_message "1. #{user_elo_48}\n2. #{user_elo_44}\n3. #{user_elo_43}\n4. #{user_elo_42}"
      end
      it 'supports -infinity' do
        user_elo_43 = Fabricate(:user, elo: 43, wins: 2, losses: 3)
        user_elo_44 = Fabricate(:user, elo: 44, wins: 2, losses: 3)
        expect(message: "#{SlackRubyBot.config.user} leaderboard -infinity").to respond_with_slack_message "1. #{user_elo_42}\n2. #{user_elo_43}\n3. #{user_elo_44}\n4. #{user_elo_48}"
      end
      it 'supports -number' do
        user_elo_43 = Fabricate(:user, elo: 43, wins: 2, losses: 3)
        expect(message: "#{SlackRubyBot.config.user} leaderboard -2").to respond_with_slack_message "1. #{user_elo_42}\n2. #{user_elo_43}"
      end
    end
    context 'without players' do
      it 'says no players' do
        expect(message: "#{SlackRubyBot.config.user} leaderboard").to respond_with_slack_message "There're no ranked players."
      end
    end
  end
  it_behaves_like 'leaderboard'
  context 'with another team' do
    let!(:team2) { Fabricate(:team) }
    let!(:user2_elo_42) { Fabricate(:user, team: team2, elo: 42, wins: 3, losses: 2) }
    let!(:user2_elo_48) { Fabricate(:user, team: team2, elo: 48, wins: 2, losses: 3) }
    it_behaves_like 'leaderboard'
  end
end
