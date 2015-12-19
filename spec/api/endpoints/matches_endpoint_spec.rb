require 'spec_helper'

describe Api::Endpoints::MatchesEndpoint do
  include Api::Test::EndpointTest

  let(:team) { Team.first || Fabricate(:team) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Match

  context 'match' do
    let(:existing_match) { Fabricate(:match) }
    it 'returns a match' do
      match = client.match(id: existing_match.id)
      expect(match.id).to eq existing_match.id.to_s
      expect(match._links.self._url).to eq "http://example.org/matches/#{existing_match.id}"
    end
  end

  context 'match' do
    let(:existing_match) { Fabricate(:match) }
    it 'returns a match with links to challenge' do
      match = client.match(id: existing_match.id)
      expect(match.id).to eq existing_match.id.to_s
      expect(match._links.challenge._url).to eq "http://example.org/challenges/#{existing_match.challenge.id}"
      expect(match._links.winners._url).to eq existing_match.winners.map { |user| "http://example.org/users/#{user.id}" }
      expect(match._links.losers._url).to eq existing_match.losers.map { |user| "http://example.org/users/#{user.id}" }
    end
  end
end
