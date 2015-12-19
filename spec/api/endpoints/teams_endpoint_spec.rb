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

    it 'cannot create a team without a SLACK_CLIENT_ID and SLACK_CLIENT_SECRET' do
      expect do
        expect { client.teams._post(code: 'code') }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq 'Missing SLACK_CLIENT_ID and/or SLACK_CLIENT_SECRET.'
          expect(json['backtrace'].split("\n").count).to eq 6
        end
      end.to_not change(Team, :count)
    end

    it 'requires code' do
      expect { client.teams._post }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq 'Invalid parameters.'
        expect(json['type']).to eq 'param_error'
      end
    end

    context 'with SLACK_CLIENT_ID and SLACK_CLIENT_SECRET' do
      before do
        ENV['SLACK_CLIENT_ID'] = 'client_id'
        ENV['SLACK_CLIENT_SECRET'] = 'client_secret'
        oauth_access = { 'bot' => { 'bot_access_token' => 'token' }, 'team_id' => 'team_id', 'team_name' => 'team_name' }
        allow_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(
          hash_including(
            code: 'code',
            client_id: 'client_id',
            client_secret: 'client_secret'
          )
        ).and_return(oauth_access)
      end
      after do
        ENV.delete 'SLACK_CLIENT_ID'
        ENV.delete 'SLACK_CLIENT_SECRET'
      end
      it 'creates a team' do
        expect(SlackGamebot::Service).to receive(:start!)
        expect do
          team = client.teams._post(code: 'code')
          expect(team.team_id).to eq 'team_id'
          expect(team.name).to eq 'team_name'
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.secret).to_not be_blank
        end.to change(Team, :count).by(1)
      end
      it 'returns a useful error when team already exists' do
        existing_team = Fabricate(:team, token: 'token')
        expect { client.teams._post(code: 'code') }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq "Team #{existing_team.name} is already registered."
        end
      end
    end
  end
end
