require 'spec_helper'

describe Api::Endpoints::GamesEndpoint do
  include Api::Test::EndpointTest

  it_behaves_like 'a cursor api', Game

  context 'game' do
    let(:existing_game) { Fabricate(:game) }
    it 'returns a game' do
      game = client.game(id: existing_game.id)
      expect(game.id).to eq existing_game.id.to_s
      expect(game._links.self._url).to eq "http://example.org/games/#{existing_game.id}"
    end
  end

  context 'game' do
    let(:existing_game) { Fabricate(:game) }
    it 'returns a game with links to teams' do
      game = client.game(id: existing_game.id)
      expect(game.id).to eq existing_game.id.to_s
      expect(game._links.teams._url).to eq "http://example.org/teams?game_id=#{existing_game.id}"
    end
  end
end
