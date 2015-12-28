require 'spec_helper'

describe Api::Endpoints::StatusEndpoint do
  include Api::Test::EndpointTest

  before do
    allow_any_instance_of(Team).to receive(:ping!).and_return(ok: 1)
  end

  context 'status' do
    it 'returns a status' do
      status = client.status
      expect(status.games_count).to eq 0
    end

    context 'with a team' do
      let!(:team) { Fabricate(:team, active: false) }
      it 'returns a status' do
        status = client.status
        expect(status.games_count).to eq 1
        game = status.games[team.game.name]
        expect(game['teams_count']).to eq 1
        expect(game['active_teams_count']).to eq 0
      end
    end

    it 'instruments endpoint with NewRelic' do
      expect(::NewRelic::Agent::Instrumentation::GrapeInstrumentation).to receive(:handle_transaction).and_call_original
      expect(::NewRelic::Agent.logger).to_not receive(:warn)
      get '/status'
      expect(last_response.status).to eq 200
    end
  end
end
