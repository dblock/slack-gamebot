require 'spec_helper'

describe Api::Endpoints::ChallengesEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Challenge

  it 'cannot return challenges for team with api off' do
    team.update_attributes!(api: false)
    expect { client.challenges(team_id: team.id).resource }.to raise_error Faraday::ClientError do |e|
      json = JSON.parse(e.response[:body])
      expect(json['error']).to eq 'Not Found'
    end
  end

  context 'challenge' do
    let(:existing_challenge) { Fabricate(:challenge) }
    it 'returns a challenge' do
      challenge = client.challenge(id: existing_challenge.id)
      expect(challenge.id).to eq existing_challenge.id.to_s
      expect(challenge._links.self._url).to eq "http://example.org/challenges/#{existing_challenge.id}"
      expect(challenge._links.team._url).to eq "http://example.org/teams/#{existing_challenge.team.id}"
    end
    it 'cannot return a challenge for team with api off' do
      team.update_attributes!(api: false)
      expect { client.challenge(id: existing_challenge.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
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
