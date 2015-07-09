require 'spec_helper'

describe User do
  context '#find_by_slack_mention!' do
    before do
      @user = Fabricate(:user)
    end
    it 'finds by slack id' do
      expect(User.find_by_slack_mention!("<@#{@user.user_id}>")).to eq @user
    end
    it 'finds by username' do
      expect(User.find_by_slack_mention!(@user.user_name)).to eq @user
    end
    it 'finds by username is case-insensitive' do
      expect(User.find_by_slack_mention!(@user.user_name.capitalize)).to eq @user
    end
    it 'requires a known user' do
      expect do
        User.find_by_slack_mention!('<@nobody>')
      end.to raise_error ArgumentError, "I don't know who <@nobody> is! Ask them to _#{SlackRubyBot.config.user} register_."
    end
  end
  context '#find_many_by_slack_mention!' do
    before do
      @users = [Fabricate(:user), Fabricate(:user)]
    end
    it 'finds by slack_id or slack_mention' do
      users = User.find_many_by_slack_mention! [@users.first.user_name, @users.last.slack_mention]
      expect(users).to contain_exactly(*@users)
    end
    it 'requires known users' do
      expect do
        User.find_many_by_slack_mention! %w(foo bar)
      end.to raise_error ArgumentError, "I don't know who foo is! Ask them to _#{SlackRubyBot.config.user} register_."
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
      expect(user1.rank).to be nil
      expect(user2.wins).to eq 0
      expect(user2.losses).to eq 0
      expect(user2.tau).to eq 0
      expect(user2.elo).to eq 0
      expect(user2.rank).to be nil
    end
  end
  context '#rank!' do
    it 'updates when elo changes' do
      user = Fabricate(:user)
      expect(user.rank).to be nil
      user.update_attributes!(elo: 65, wins: 1)
      expect(user.rank).to eq 1
    end
    it 'ranks four players' do
      user1 = Fabricate(:user, elo: 100, wins: 4, losses: 0)
      user2 = Fabricate(:user, elo: 40, wins: 1, losses: 1)
      user3 = Fabricate(:user, elo: 60, wins: 2, losses: 0)
      user4 = Fabricate(:user, elo: 80, wins: 3, losses: 0)
      expect(user1.reload.rank).to eq 1
      expect(user2.reload.rank).to eq 4
      expect(user3.reload.rank).to eq 3
      expect(user4.reload.rank).to eq 2
    end
    it 'ranks players with the same elo and different wins/losses'
    it 'ranks players with the same elo and wins/losses equally' do
      user1 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      user2 = Fabricate(:user, elo: 2, wins: 1, losses: 1)
      expect(user1.rank).to eq 1
      expect(user1.rank).to eq user2.rank
    end
    it 'is updated for all users' do
      user1 = Fabricate(:user, elo: 65, wins: 1)
      expect(user1.rank).to eq 1
      user2 = Fabricate(:user, elo: 75, wins: 2)
      expect(user1.reload.rank).to eq 2
      expect(user2.rank).to eq 1
      user1.update_attributes!(elo: 100, wins: 3)
      expect(user1.rank).to eq 1
      expect(user2.reload.rank).to eq 2
    end
  end
  context '.ranked' do
    it 'returns an empty list' do
      expect(User.ranked).to eq []
    end
    it 'ranks incrementally' do
      user1 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      user2 = Fabricate(:user, elo: 2, wins: 1, losses: 1)
      expect(User.ranked).to eq [user2, user1]
    end
    it 'limits to max' do
      Fabricate(:user, elo: 1, wins: 1, losses: 1)
      user2 = Fabricate(:user, elo: 2, wins: 1, losses: 1)
      Fabricate(:user, elo: 1, wins: 1, losses: 1)
      expect(User.ranked(1)).to eq [user2]
    end
    it 'ignores players without rank' do
      user1 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      Fabricate(:user)
      expect(User.ranked).to eq [user1]
    end
  end
  context '.rank_section' do
    it 'returns a section' do
      user1 = Fabricate(:user, elo: 100, wins: 4, losses: 0)
      user2 = Fabricate(:user, elo: 40, wins: 1, losses: 1)
      user3 = Fabricate(:user, elo: 60, wins: 2, losses: 0)
      user4 = Fabricate(:user, elo: 80, wins: 3, losses: 0)
      [user1, user2, user3, user4].each(&:reload)
      expect(User.rank_section([user1])).to eq [user1]
      expect(User.rank_section([user1, user3])).to eq [user1, user4, user3]
      expect(User.rank_section([user1, user3, user4])).to eq [user1, user4, user3]
    end
  end
end
