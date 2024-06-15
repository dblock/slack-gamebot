require 'spec_helper'

describe User do
  let(:team) { Fabricate(:team) }

  describe '#find_by_slack_mention!' do
    let(:web_client) { double(Slack::Web::Client, users_info: nil) }
    let(:client) { double(Slack::RealTime::Client, owner: team, web_client: web_client) }
    let!(:user) { Fabricate(:user, team: team, nickname: 'bob') }

    it 'finds by slack id' do
      expect(User.find_by_slack_mention!(client, "<@#{user.user_id}>")).to eq user
    end

    it 'finds by username' do
      expect(User.find_by_slack_mention!(client, user.user_name)).to eq user
    end

    it 'finds by username is case-insensitive' do
      expect(User.find_by_slack_mention!(client, user.user_name.capitalize)).to eq user
    end

    it 'requires a known user' do
      expect do
        User.find_by_slack_mention!(client, '<@nobody>')
      end.to raise_error SlackGamebot::Error, "I don't know who <@nobody> is! Ask them to _register_."
    end

    it 'finds by nickname' do
      expect(User.find_by_slack_mention!(client, user.nickname)).to eq user
    end

    %w[here channel].each do |name|
      it "always finds #{name}" do
        mention = "<!#{name}>"
        expect do
          3.times do
            expect(User.find_by_slack_mention!(client, mention)).to be_a User
          end
        end.to change(User, :count).by(1)
      end
    end
  end

  context 'with a mismatching user id in slack_mention' do
    let!(:user) { Fabricate(:user, team: team, nickname: 'bob') }
    let(:web_client) { double(Slack::Web::Client, users_info: { user: { id: user.user_id, name: user.user_name } }) }
    let(:client) { double(Slack::RealTime::Client, owner: team, web_client: web_client) }

    it 'finds by different slack id returned from slack info' do
      expect(User.find_by_slack_mention!(client, '<@unknown>')).to eq user
    end
  end

  describe '#find_many_by_slack_mention!' do
    let(:web_client) { double(Slack::Web::Client, users_info: nil) }
    let(:client) { double(Slack::RealTime::Client, owner: team, web_client: web_client) }
    let!(:users) { [Fabricate(:user, team: team), Fabricate(:user, team: team)] }

    it 'finds by slack_id or slack_mention' do
      results = User.find_many_by_slack_mention!(client, [users.first.user_name, users.last.slack_mention])
      expect(results).to match_array(users)
    end

    it 'requires known users' do
      expect do
        User.find_many_by_slack_mention!(client, %w[foo bar])
      end.to raise_error SlackGamebot::Error, "I don't know who foo is! Ask them to _register_."
    end
  end

  describe '#find_create_or_update_by_slack_id!', vcr: { cassette_name: 'user_info' } do
    let(:client) { SlackRubyBot::Client.new }

    before do
      client.owner = team
    end

    context 'without a user' do
      it 'creates a user' do
        expect do
          user = User.find_create_or_update_by_slack_id!(client, 'U42')
          expect(user).not_to be_nil
          expect(user.user_id).to eq 'U42'
          expect(user.user_name).to eq 'username'
        end.to change(User, :count).by(1)
      end
    end

    context 'with a user' do
      let!(:user) { Fabricate(:user, team: team) }

      it 'creates another user' do
        expect do
          User.find_create_or_update_by_slack_id!(client, 'U42')
        end.to change(User, :count).by(1)
      end

      it 'updates the username of the existing user' do
        expect do
          User.find_create_or_update_by_slack_id!(client, user.user_id)
        end.not_to change(User, :count)
        expect(user.reload.user_name).to eq 'username'
      end
    end
  end

  describe '#to_s' do
    let(:user) { Fabricate(:user, elo: 48, team: Fabricate(:team, elo: 2)) }

    it 'respects team elo' do
      expect(user.to_s).to include 'elo: 50'
    end

    context 'unregistered user' do
      before do
        user.update_attributes!(registered: false)
      end

      it 'hides name' do
        expect(user.to_s).to eq '<unregistered>: 0 wins, 0 losses (elo: 50)'
      end
    end

    context 'user with nickname' do
      before do
        user.update_attributes!(nickname: 'bob')
      end

      it 'rewrites user name' do
        expect(user.to_s).to eq 'bob: 0 wins, 0 losses (elo: 50)'
      end
    end

    context 'with a longest winning streak >= 3' do
      before do
        user.update_attributes!(winning_streak: 3)
      end

      it 'displays lws' do
        expect(user.to_s).to eq "#{user.user_name}: 0 wins, 0 losses (elo: 50, lws: 3)"
      end
    end

    context 'equal streaks' do
      before do
        user.update_attributes!(winning_streak: 5, losing_streak: 5)
      end

      it 'prefers winning streak' do
        expect(user.to_s).to eq "#{user.user_name}: 0 wins, 0 losses (elo: 50, lws: 5)"
      end
    end

    context 'with a longest losing streak >= 3' do
      before do
        user.update_attributes!(losing_streak: 3, winning_streak: 2)
      end

      it 'displays lls' do
        expect(user.to_s).to eq "#{user.user_name}: 0 wins, 0 losses (elo: 50, lls: 3)"
      end
    end
  end

  describe '#reset_all' do
    it 'resets all user stats' do
      user1 = Fabricate(:user, elo: 48, losses: 1, wins: 2, ties: 3, tau: 0.5)
      user2 = Fabricate(:user, elo: 54, losses: 2, wins: 1, tau: 1.5)
      User.reset_all!(user1.team)
      user1.reload
      user2.reload
      expect(user1.wins).to eq 0
      expect(user1.losses).to eq 0
      expect(user1.ties).to eq 0
      expect(user1.tau).to eq 0
      expect(user1.elo).to eq 0
      expect(user1.rank).to be_nil
      expect(user1.winning_streak).to eq 0
      expect(user1.losing_streak).to eq 0
      expect(user1.elo_history).to eq []
      expect(user2.wins).to eq 0
      expect(user2.losses).to eq 0
      expect(user2.ties).to eq 0
      expect(user2.tau).to eq 0
      expect(user2.elo).to eq 0
      expect(user2.rank).to be_nil
      expect(user2.winning_streak).to eq 0
      expect(user2.losing_streak).to eq 0
      expect(user2.elo_history).to eq []
    end
  end

  describe '#rank!' do
    it 'updates when elo changes' do
      user = Fabricate(:user)
      expect(user.rank).to be_nil
      user.update_attributes!(elo: 65, wins: 1)
      expect(user.rank).to eq 1
    end

    it 'stores elo history' do
      user = Fabricate(:user)
      user.update_attributes!(elo: 65, wins: 1)
      expect(user.elo_history).to eq [0, 65]
      user.update_attributes!(elo: 45, wins: 2)
      expect(user.elo_history).to eq [0, 65, 45]
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

    it 'ranks players with the same elo and different wins' do
      user1 = Fabricate(:user, elo: 40, wins: 1, losses: 0)
      user2 = Fabricate(:user, elo: 40, wins: 4, losses: 0)
      expect(user1.reload.rank).to eq 2
      expect(user2.reload.rank).to eq 1
    end

    it 'ranks players with the same elo, wins and losses and different ties' do
      user1 = Fabricate(:user, elo: 40, wins: 1, losses: 0, ties: 0)
      user2 = Fabricate(:user, elo: 40, wins: 1, losses: 0, ties: 1)
      expect(user1.reload.rank).to eq 2
      expect(user2.reload.rank).to eq 1
    end

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

    it 'does not rank unregistered users' do
      user1 = Fabricate(:user, elo: 40, wins: 1, losses: 0, registered: false)
      user2 = Fabricate(:user, elo: 40, wins: 4, losses: 0)
      expect(user1.reload.rank).to be_nil
      expect(user2.reload.rank).to eq 1
    end
  end

  describe '.ranked' do
    it 'returns an empty list' do
      expect(User.ranked).to eq []
    end

    it 'ignores players without rank' do
      user1 = Fabricate(:user, elo: 1, wins: 1, losses: 1)
      Fabricate(:user)
      expect(User.ranked).to eq [user1]
    end
  end

  describe '.rank_section' do
    let(:team) { Fabricate(:team) }

    it 'returns a section' do
      user1 = Fabricate(:user, team: team, elo: 100, wins: 4, losses: 0)
      user2 = Fabricate(:user, team: team, elo: 40, wins: 1, losses: 1)
      user3 = Fabricate(:user, team: team, elo: 60, wins: 2, losses: 0)
      user4 = Fabricate(:user, team: team, elo: 80, wins: 3, losses: 0)
      [user1, user2, user3, user4].each(&:reload)
      expect(User.rank_section(team, [user1])).to eq [user1]
      expect(User.rank_section(team, [user1, user3])).to eq [user1, user4, user3]
      expect(User.rank_section(team, [user1, user3, user4])).to eq [user1, user4, user3]
    end

    it 'limits by team' do
      user = Fabricate(:user, elo: 100, wins: 4, losses: 0)
      expect(User.rank_section(Fabricate(:team), [user])).to eq []
    end

    it 'only returns one unranked user' do
      user1 = Fabricate(:user, team: team)
      user2 = Fabricate(:user, team: team)
      expect(User.rank_section(team, [user1])).to eq [user1]
      expect(User.rank_section(team, [user1, user2])).to eq [user1, user2]
    end
  end

  describe '#calculate_streaks!' do
    let(:user) { Fabricate(:user) }

    it 'is 0 by default' do
      expect(user.winning_streak).to eq 0
      expect(user.losing_streak).to eq 0
    end

    it 'is 0 without matches' do
      user.calculate_streaks!
      expect(user.winning_streak).to eq 0
      expect(user.losing_streak).to eq 0
    end
  end
end
