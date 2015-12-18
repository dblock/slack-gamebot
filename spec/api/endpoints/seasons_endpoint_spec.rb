require 'spec_helper'

describe Api::Endpoints::SeasonsEndpoint do
  include Api::Test::EndpointTest

  let(:team) { Team.first || Fabricate(:team) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Season

  context 'season' do
    let(:existing_season) { Fabricate(:season) }
    it 'returns a season' do
      season = client.season(id: existing_season.id)
      expect(season.id).to eq existing_season.id.to_s
      expect(season._links.self._url).to eq "http://example.org/seasons/#{existing_season.id}"
    end
  end

  context 'current season' do
    before do
      Fabricate(:match)
    end
    it 'returns the current season' do
      season = client.current_season
      expect(season.id).to eq 'current'
      expect(season._links.self._url).to eq 'http://example.org/seasons/current'
    end
  end
end
