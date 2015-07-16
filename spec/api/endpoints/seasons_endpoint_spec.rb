require 'spec_helper'

describe Api::Endpoints::SeasonsEndpoint do
  include Api::Test::EndpointTest

  it_behaves_like 'a cursor api', Season

  context 'season' do
    let(:existing_season) { Fabricate(:season) }
    it 'returns a season' do
      season = client.season(id: existing_season.id)
      expect(season.id).to eq existing_season.id.to_s
      expect(season._links.self._url).to eq "http://example.org/seasons/#{existing_season.id}"
    end
  end
end
