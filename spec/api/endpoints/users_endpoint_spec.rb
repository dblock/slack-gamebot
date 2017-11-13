require 'spec_helper'

describe Api::Endpoints::UsersEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', User

  context 'user' do
    let(:existing_user) { Fabricate(:user) }
    it 'returns a user' do
      user = client.user(id: existing_user.id)
      expect(user.id).to eq existing_user.id.to_s
      expect(user.user_name).to eq existing_user.user_name
      expect(user._links.self._url).to eq "http://example.org/api/users/#{existing_user.id}"
    end
    it 'cannot return a user for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.user(id: existing_user.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
  end

  context 'users' do
    let!(:user_elo1) { Fabricate(:user, elo: 1, wins: 1, team: team, captain: true) }
    let!(:user_elo3) { Fabricate(:user, elo: 3, wins: 3, team: team) }
    let!(:user_elo2) { Fabricate(:user, elo: 2, wins: 2, team: team) }
    it 'cannot return users for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.users(team_id: team.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
    it 'returns users sorted by elo' do
      users = client.users(team_id: team.id, sort: 'elo')
      expect(users.map(&:id)).to eq [user_elo1, user_elo2, user_elo3].map(&:id).map(&:to_s)
    end
    it 'returns users sorted by -elo' do
      users = client.users(team_id: team.id, sort: '-elo')
      expect(users.map(&:id)).to eq [user_elo3, user_elo2, user_elo1].map(&:id).map(&:to_s)
    end
    it 'returns users sorted by rank' do
      users = client.users(team_id: team.id, sort: 'rank')
      expect(users.map(&:id)).to eq [user_elo3, user_elo2, user_elo1].map(&:id).map(&:to_s)
    end
    it 'returns users sorted by -rank' do
      users = client.users(team_id: team.id, sort: '-rank')
      expect(users.map(&:id)).to eq [user_elo1, user_elo2, user_elo3].map(&:id).map(&:to_s)
    end
    it 'returns captains' do
      users = client.users(team_id: team.id, captain: true)
      expect(users.map(&:id)).to eq [user_elo1].map(&:id).map(&:to_s)
    end
  end
end
