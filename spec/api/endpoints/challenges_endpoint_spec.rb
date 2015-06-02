require 'spec_helper'

describe Api::Endpoints::ChallengesEndpoint do
  include Api::Test::EndpointTest

  it_behaves_like 'a cursor api', Challenge

  context 'challenge' do
    let(:existing_challenge) { Fabricate(:challenge) }
    it 'returns a challenge' do
      challenge = client.challenge(id: existing_challenge.id)
      expect(challenge.id).to eq existing_challenge.id.to_s
      expect(challenge._links.self._url).to eq "http://example.org/challenges/#{existing_challenge.id}"
    end
  end

  context 'doubles challenge' do
    let(:existing_challenge) { Fabricate(:doubles_challenge) }
    before do
      existing_challenge.accept!(existing_challenge.challenged.first)
      existing_challenge.lose!(existing_challenge.challengers.first)
    end
    it 'returns a challenge with links to challengers, challenged and played match' do
      challenge = client.challenge(id: existing_challenge.id)
      expect(challenge.id).to eq existing_challenge.id.to_s
      expect(challenge._links.challengers._url).to eq existing_challenge.challengers.map { |user| "http://example.org/users/#{user.id}" }
      expect(challenge._links.challenged._url).to eq existing_challenge.challenged.map { |user| "http://example.org/users/#{user.id}" }
      expect(challenge._links.match._url).to eq "http://example.org/matches/#{existing_challenge.match.id}"
    end
  end
end
