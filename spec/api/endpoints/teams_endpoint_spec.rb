require 'spec_helper'

describe Api::Endpoints::TeamsEndpoint do
  include Api::Test::EndpointTest

  context 'cursor' do
    it_behaves_like 'a cursor api', Team
  end

  let!(:game) { Fabricate(:game) }

  context 'team' do
    let(:existing_team) { Fabricate(:team, api: true, game: game) }
    it 'returns a team' do
      team = client.team(id: existing_team.id)
      expect(team.id).to eq existing_team.id.to_s
      expect(team._links.self._url).to eq "http://example.org/api/teams/#{existing_team.id}"
    end
  end

  context 'teams' do
    context 'active/inactive' do
      let!(:active_team) { Fabricate(:team, api: true, game: game, active: true) }
      let!(:inactive_team) { Fabricate(:team, api: true, game: game, active: false) }
      it 'returns all teams' do
        teams = client.teams
        expect(teams.count).to eq 2
      end
      it 'returns active teams' do
        teams = client.teams(active: true)
        expect(teams.count).to eq 1
        expect(teams.to_a.first.team_id).to eq active_team.team_id
      end
    end
    context 'game_id' do
      let!(:team1) { Fabricate(:team, api: true, game: game) }
      let!(:team2) { Fabricate(:team, api: true, game: Fabricate(:game)) }
      it 'returns all teams' do
        teams = client.teams
        expect(teams.count).to eq 2
      end
      it 'returns team by game' do
        teams = client.teams(game_id: game.id.to_s)
        expect(teams.count).to eq 1
        expect(teams.to_a.first.team_id).to eq team1.team_id
      end
    end
    context 'api on/off' do
      let!(:team_api_on) { Fabricate(:team, api: true, game: game) }
      let!(:team_api_off) { Fabricate(:team, api: false, game: game) }
      it 'only returns teams with api on' do
        teams = client.teams
        expect(teams.count).to eq 1
        expect(teams.to_a.first.team_id).to eq team_api_on.team_id
      end
    end
    context 'game_id' do
      let!(:team1) { Fabricate(:team, api: true, game: game) }
      let!(:team2) { Fabricate(:team, api: true, game: Fabricate(:game)) }
      it 'returns all teams' do
        teams = client.teams
        expect(teams.count).to eq 2
      end
      it 'returns team by game' do
        teams = client.teams(game_id: game.id.to_s)
        expect(teams.count).to eq 1
        expect(teams.to_a.first.team_id).to eq team1.team_id
      end
    end
  end

  context 'team' do
    let(:existing_team) { Fabricate(:team, api: true, game: game) }
    it 'returns a team with links to challenges, users and matches' do
      team = client.team(id: existing_team.id)
      expect(team.id).to eq existing_team.id.to_s
      expect(team._links.users._url).to eq "http://example.org/api/users?team_id=#{existing_team.id}"
      expect(team._links.challenges._url).to eq "http://example.org/api/challenges?team_id=#{existing_team.id}"
      expect(team._links.matches._url).to eq "http://example.org/api/matches?team_id=#{existing_team.id}"
      expect(team._links.seasons._url).to eq "http://example.org/api/seasons?team_id=#{existing_team.id}"
      expect(team._links.game._url).to eq "http://example.org/api/games/#{existing_team.game.id}"
    end

    it 'cannot return a team with api off' do
      existing_team.update_attributes!(api: false)
      expect { client.team(id: existing_team.id).resource }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['error']).to eq 'Not Found'
      end
    end

    it 'cannot create a team without a game' do
      expect do
        expect { client.teams._post(code: 'code').resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq 'Invalid parameters.'
          expect(json['detail']).to eq('game, game_id' => ['are missing, exactly one parameter must be provided'])
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

    context 'register' do
      before do
        oauth_access = { 'bot' => { 'bot_access_token' => 'token' }, 'team_id' => 'team_id', 'team_name' => 'team_name' }
        allow_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(
          hash_including(
            code: 'code',
            client_id: game.client_id,
            client_secret: game.client_secret
          )
        ).and_return(oauth_access)
      end
      it 'creates a team with game name' do
        expect(SlackGamebot::Service.instance).to receive(:start!)
        expect do
          team = client.teams._post(code: 'code', game: game.name)
          expect(team.team_id).to eq 'team_id'
          expect(team.name).to eq 'team_name'
          team = Team.find(team.id)
          expect(team.game).to eq game
          expect(team.token).to eq 'token'
          expect(team.aliases).to eq game.aliases
        end.to change(Team, :count).by(1)
      end
      it 'creates a team with game id' do
        expect(SlackGamebot::Service.instance).to receive(:start!)
        expect do
          team = client.teams._post(code: 'code', game_id: game.id.to_s)
          expect(team.team_id).to eq 'team_id'
          expect(team.name).to eq 'team_name'
          team = Team.find(team.id)
          expect(team.game).to eq game
          expect(team.token).to eq 'token'
          expect(team.aliases).to eq game.aliases
        end.to change(Team, :count).by(1)
      end
      it 'reactivates a deactivated team' do
        expect(SlackGamebot::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, api: true, game: game, token: 'token', active: false, aliases: %w[foo bar])
        expect do
          team = client.teams._post(code: 'code', game: existing_team.game.name)
          expect(team.team_id).to eq existing_team.team_id
          expect(team.name).to eq existing_team.name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.aliases).to eq %w[foo bar]
        end.to_not change(Team, :count)
      end
      it 'updates a reactivated team with a new token' do
        expect(SlackGamebot::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, api: true, game: game, token: 'old', team_id: 'team_id', active: false)
        expect do
          team = client.teams._post(code: 'code', game: existing_team.game.name)
          expect(team.team_id).to eq existing_team.team_id
          expect(team.name).to eq existing_team.name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
        end.to_not change(Team, :count)
      end
      it 'cannot switch games' do
        expect(SlackGamebot::Service.instance).to_not receive(:start!)
        Fabricate(:team, api: true, game: Fabricate(:game), token: 'token', active: false)
        expect { client.teams._post(code: 'code', game_id: game.id.to_s) }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Invalid Game'
        end
      end
      it 'returns a useful error when team already exists' do
        expect(SlackGamebot::Service.instance).to_not receive(:start!)
        existing_team = Fabricate(:team, api: true, game: game, token: 'token')
        expect { client.teams._post(code: 'code', game: game.name) }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq "Team #{existing_team.name} is already registered."
        end
      end
    end

    it 'reactivates a deactivated team with a different code' do
      expect(SlackGamebot::Service.instance).to receive(:start!)
      existing_team = Fabricate(:team, api: true, game: game, token: 'token', active: false, aliases: %w[foo bar])
      oauth_access = { 'bot' => { 'bot_access_token' => 'another_token' }, 'team_id' => existing_team.team_id, 'team_name' => existing_team.name }
      allow_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(
        hash_including(
          code: 'code',
          client_id: game.client_id,
          client_secret: game.client_secret
        )
      ).and_return(oauth_access)
      expect do
        team = client.teams._post(code: 'code', game: existing_team.game.name)
        expect(team.team_id).to eq existing_team.team_id
        expect(team.name).to eq existing_team.name
        expect(team.active).to be true
        team = Team.find(team.id)
        expect(team.token).to eq 'another_token'
        expect(team.active).to be true
        expect(team.aliases).to eq %w[foo bar]
      end.to_not change(Team, :count)
    end
  end
end
