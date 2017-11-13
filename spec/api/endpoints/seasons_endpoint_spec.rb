require 'spec_helper'

describe Api::Endpoints::SeasonsEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Season

  it 'cannot return seasons for a team with api off' do
    team.update_attributes!(api: false)
    expect { client.seasons(team_id: team.id).resource }.to raise_error Faraday::ClientError do |e|
      json = JSON.parse(e.response[:body])
      expect(json['error']).to eq 'Not Found'
    end
  end

  context 'season' do
    let(:existing_season) { Fabricate(:season) }
    it 'returns a season' do
      season = client.season(id: existing_season.id)
      expect(season.id).to eq existing_season.id.to_s
      expect(season._links.self._url).to eq "http://example.org/api/seasons/#{existing_season.id}"
    end
    it 'cannot return a season for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.season(id: existing_season.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
  end

  context 'current season' do
    before do
      Fabricate(:match)
    end
    it 'returns the current season' do
      season = client.current_season(team_id: team.id.to_s)
      expect(season.id).to eq 'current'
      expect(season._links.self._url).to eq 'http://example.org/api/seasons/current'
    end
    it 'cannot return the current season for team with api off' do
      team.update_attributes!(api: false)
      expect { client.current_season(team_id: team.id.to_s).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
  end
end
