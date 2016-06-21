require 'spec_helper'

describe Api::Endpoints::StatusEndpoint do
  include Api::Test::EndpointTest

  before do
    allow_any_instance_of(Team).to receive(:ping!).and_return(ok: 1)
  end

  context 'status' do
    it 'returns a status' do
      status = client.status
      expect(status.games_count).to eq 0
    end

    context 'with a team that is inactive' do
      let!(:team) { Fabricate(:team, api: true, active: false) }
      it 'returns a status' do
        status = client.status
        expect(status.games_count).to eq 1
        game = status.games[team.game.name]
        expect(game['teams_count']).to eq 1
        expect(game['active_teams_count']).to eq 0
        expect(game['api_teams_count']).to eq 1
      end
    end

    context 'with a team with api off' do
      let!(:team) { Fabricate(:team, api: false) }
      it 'returns total counts anyway' do
        status = client.status
        expect(status.games_count).to eq 1
        game = status.games[team.game.name]
        expect(game['teams_count']).to eq 1
        expect(game['api_teams_count']).to eq 0
      end
    end
  end
end
