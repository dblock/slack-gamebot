require 'spec_helper'

describe SlackGamebot::Commands::Leaderboard do
  let!(:user_elo_42) { Fabricate(:user, elo: 42, wins: 3, losses: 2) }
  let!(:user_elo_48) { Fabricate(:user, elo: 48, wins: 2, losses: 3) }
  it 'displays leaderboard sorted by elo' do
    expect(message: 'gamebot leaderboard').to respond_with_slack_message "1. #{user_elo_48}\n2. #{user_elo_42}"
  end
  it 'limits to max' do
    expect(message: 'gamebot leaderboard 1').to respond_with_slack_message "1. #{user_elo_48}"
  end
  it 'supports infinity' do
    user_elo_43 = Fabricate(:user, elo: 43, wins: 2, losses: 3)
    user_elo_44 = Fabricate(:user, elo: 44, wins: 2, losses: 3)
    expect(message: 'gamebot leaderboard infinity').to respond_with_slack_message "1. #{user_elo_48}\n2. #{user_elo_44}\n3. #{user_elo_43}\n4. #{user_elo_42}"
  end
end
