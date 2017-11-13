require 'spec_helper'

describe Api::Endpoints::MatchesEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Match

  it 'cannot return matches for a team with api off' do
    team.update_attributes!(api: false)
    expect { client.matches(team_id: team.id).resource }.to raise_error Faraday::ClientError do |e|
      json = JSON.parse(e.response[:body])
      expect(json['error']).to eq 'Not Found'
    end
  end

  context 'match' do
    let(:existing_match) { Fabricate(:match, team: team) }
    it 'returns a match' do
      match = client.match(id: existing_match.id)
      expect(match.id).to eq existing_match.id.to_s
      expect(match._links.self._url).to eq "http://example.org/api/matches/#{existing_match.id}"
    end
    it 'cannot return a match for a team with api off' do
      team.update_attributes!(api: false)
      expect { client.match(id: existing_match.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end
  end

  context 'match' do
    let(:existing_match) { Fabricate(:match) }
    it 'returns a match with links to challenge' do
      match = client.match(id: existing_match.id)
      expect(match.id).to eq existing_match.id.to_s
      expect(match._links.challenge._url).to eq "http://example.org/api/challenges/#{existing_match.challenge.id}"
      expect(match._links.winners._url).to eq existing_match.winners.map { |user| "http://example.org/api/users/#{user.id}" }
      expect(match._links.losers._url).to eq existing_match.losers.map { |user| "http://example.org/api/users/#{user.id}" }
    end
  end
end
