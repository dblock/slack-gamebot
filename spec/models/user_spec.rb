require 'spec_helper'

describe User do
  context '#find_by_slack_mention' do
    before do
      @user = Fabricate(:user)
    end
    it 'finds by slack id' do
      expect(User.find_by_slack_mention("<@#{@user.user_id}>")).to eq @user
    end
    it 'finds by username' do
      expect(User.find_by_slack_mention(@user.user_name)).to eq @user
    end
    it 'finds by username is case-insensitive' do
      expect(User.find_by_slack_mention(@user.user_name.capitalize)).to eq @user
    end
  end
  context '#find_create_or_update_by_slack_id!', vcr: { cassette_name: 'user_info' } do
    context 'without a user' do
      it 'creates a user' do
        expect do
          user = User.find_create_or_update_by_slack_id!('U42')
          expect(user).to_not be_nil
          expect(user.user_id).to eq 'U42'
          expect(user.user_name).to eq 'username'
        end.to change(User, :count).by(1)
      end
    end
    context 'with a user' do
      before do
        @user = Fabricate(:user)
      end
      it 'creates another user' do
        expect do
          User.find_create_or_update_by_slack_id!('U42')
        end.to change(User, :count).by(1)
      end
      it 'updates the username of the existing user' do
        expect do
          User.find_create_or_update_by_slack_id!(@user.user_id)
        end.to_not change(User, :count)
        expect(@user.reload.user_name).to eq 'username'
      end
    end
  end
  context '#leaderboard' do
    it 'returns no players' do
      expect(User.leaderboard).to eq 'No players.'
    end
    it 'ranks incrementally' do
      user1 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      user2 = Fabricate(:user, elo: 2, wins: 1, losses: 1)
      expect(User.leaderboard).to eq "1. #{user2}\n2. #{user1}"
    end
    it 'ranks players with the same elo equally' do
      user1 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      user2 = Fabricate(:user, elo: 2, wins: 1, losses: 1)
      user3 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      expect(User.leaderboard).to eq "1. #{user2}\n2. #{user1}\n2. #{user3}"
    end
    it 'limits to max' do
      Fabricate(:user, elo: 1, wins: 1, losses: 1)
      user2 = Fabricate(:user, elo: 2, wins: 1, losses: 1)
      Fabricate(:user, elo: 1, wins: 1, losses: 1)
      expect(User.leaderboard(1)).to eq "1. #{user2}"
    end
    it 'ignores players without wins or losses' do
      user1 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      Fabricate(:user, elo: 2, wins: 0, losses: 0)
      expect(User.leaderboard).to eq "1. #{user1}"
    end
    it 'first game' do
      user1 = Fabricate(:user, elo: 48, wins: 1, losses: 0)
      user2 = Fabricate(:user, elo: -48, wins: 0, losses: 1)
      expect(User.leaderboard).to eq "1. #{user1}\n2. #{user2}"
    end
  end
  context '#reset_all' do
    it 'resets all user stats' do
      user1 = Fabricate(:user, elo: 48, losses: 1, wins: 2, tau: 0.5)
      user2 = Fabricate(:user, elo: 54, losses: 2, wins: 1, tau: 1.5)
      User.reset_all!
      user1.reload
      user2.reload
      expect(user1.wins).to eq 0
      expect(user1.losses).to eq 0
      expect(user1.tau).to eq 0
      expect(user1.elo).to eq 0
      expect(user2.wins).to eq 0
      expect(user2.losses).to eq 0
      expect(user2.tau).to eq 0
      expect(user2.elo).to eq 0
    end
  end
end
