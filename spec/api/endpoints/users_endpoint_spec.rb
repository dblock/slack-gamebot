require 'spec_helper'

describe Api::Endpoints::UsersEndpoint do
  include Api::Test::EndpointTest

  it_behaves_like 'a cursor api', User

  context 'user' do
    let(:existing_user) { Fabricate(:user) }
    it 'returns a user' do
      user = client.user(id: existing_user.id)
      expect(user.id).to eq existing_user.id.to_s
      expect(user.user_name).to eq existing_user.user_name
      expect(user._links.self._url).to eq "http://example.org/users/#{existing_user.id}"
    end
  end

  context 'users' do
    let!(:user_elo1) { Fabricate(:user, elo: 1, wins: 1) }
    let!(:user_elo3) { Fabricate(:user, elo: 3, wins: 3) }
    let!(:user_elo2) { Fabricate(:user, elo: 2, wins: 2) }
    it 'returns users sorted by elo' do
      users = client.users(sort: 'elo')
      expect(users.map(&:id)).to eq [user_elo1, user_elo2, user_elo3].map(&:id).map(&:to_s)
    end
    it 'returns users sorted by -elo' do
      users = client.users(sort: '-elo')
      expect(users.map(&:id)).to eq [user_elo3, user_elo2, user_elo1].map(&:id).map(&:to_s)
    end
    it 'returns users sorted by rank' do
      users = client.users(sort: 'rank')
      expect(users.map(&:id)).to eq [user_elo3, user_elo2, user_elo1].map(&:id).map(&:to_s)
    end
    it 'returns users sorted by -rank' do
      users = client.users(sort: '-rank')
      expect(users.map(&:id)).to eq [user_elo1, user_elo2, user_elo3].map(&:id).map(&:to_s)
    end
  end
end
