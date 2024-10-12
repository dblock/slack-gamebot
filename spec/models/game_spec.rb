require 'spec_helper'

describe Game do
  describe '#find_or_create_from_env!' do
    before do
      ENV['SLACK_CLIENT_ID'] = 'slack_client_id'
      ENV['SLACK_CLIENT_SECRET'] = 'slack_client_secret'
      ENV['SLACK_RUBY_BOT_ALIASES'] = 'pp :pong:'
    end

    after do
      ENV.delete 'SLACK_CLIENT_ID'
      ENV.delete 'SLACK_CLIENT_SECRET'
      ENV.delete 'SLACK_RUBY_BOT_ALIASES'
    end

    context 'game' do
      it 'creates a game' do
        expect { Game.find_or_create_from_env! }.to change(Game, :count).by(1)
        game = Game.first
        expect(game.name).to be_nil
        expect(game.client_id).to eq 'slack_client_id'
        expect(game.client_secret).to eq 'slack_client_secret'
        expect(game.aliases).to eq(['pp', ':pong:'])
      end
    end
  end

  describe '#destroy' do
    let!(:game) { Fabricate(:game) }

    it 'can destroy a game' do
      expect do
        game.destroy
      end.to change(Game, :count).by(-1)
    end

    context 'with teams' do
      let!(:team) { Fabricate(:team, game:) }

      it 'cannot destroy a game that has teams' do
        expect do
          expect do
            game.destroy
          end.to raise_error 'The game has teams and cannot be destroyed.'
        end.not_to change(Game, :count)
      end
    end
  end
end
