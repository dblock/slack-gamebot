require 'spec_helper'

describe Api::Endpoints::TeamsEndpoint do
  include Api::Test::EndpointTest

  it_behaves_like 'a cursor api', Team

  context 'team' do
    let(:existing_team) { Fabricate(:team) }
    it 'returns a team' do
      team = client.team(id: existing_team.id)
      expect(team.id).to eq existing_team.id.to_s
      expect(team._links.self._url).to eq "http://example.org/teams/#{existing_team.id}"
    end
  end

  context 'team' do
    let(:existing_team) { Fabricate(:team) }
    it 'returns a team with links to challenges, users and matches' do
      team = client.team(id: existing_team.id)
      expect(team.id).to eq existing_team.id.to_s
      expect(team._links.users._url).to eq "http://example.org/users?team_id=#{existing_team.id}"
      expect(team._links.challenges._url).to eq "http://example.org/challenges?team_id=#{existing_team.id}"
      expect(team._links.matches._url).to eq "http://example.org/matches?team_id=#{existing_team.id}"
      expect(team._links.seasons._url).to eq "http://example.org/seasons?team_id=#{existing_team.id}"
    end

    it 'creates a team' do
      expect(SlackGamebot::Service).to receive(:start!)
      oauth_access = { 'bot' => { 'bot_access_token' => 'token' } }
      allow_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(hash_including(code: 'code')).and_return(oauth_access)
      allow_any_instance_of(Slack::Web::Client).to receive(:team_info).and_return('team' => { 'id' => 'id', 'name' => 'name', 'domain' => 'domain' })
      expect do
        team = client.teams._post(code: 'code')
        expect(team.team_id).to eq 'id'
        expect(team.name).to eq 'name'
        expect(team.domain).to eq 'domain'
        team = Team.find(team.id)
        expect(team.token).to eq 'token'
        expect(team.secret).to_not be_blank
      end.to change(Team, :count).by(1)
    end
  end
end
