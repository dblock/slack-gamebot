require 'spec_helper'

describe UserRank do
  context '#from_user' do
    it 'creates a record' do
      user = Fabricate(:user)
      user_rank = UserRank.from_user(user)
      expect(user_rank.user).to eq user
      expect(user_rank.user_name).to eq user.user_name
      expect(user_rank.wins).to eq user.wins
      expect(user_rank.losses).to eq user.losses
      expect(user_rank.tau).to eq user.tau
      expect(user_rank.elo).to eq user.elo
      expect(user_rank.elo_history).to eq user.elo_history
      expect(user_rank.rank).to eq user.rank
    end
  end
end
