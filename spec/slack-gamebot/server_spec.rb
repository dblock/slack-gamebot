require 'spec_helper'

describe SlackGamebot::Server do
  let(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  context 'send_gifs' do
    context 'default' do
      let(:team) { Fabricate(:team) }
      it 'true' do
        expect(app.send(:client).send_gifs?).to be true
      end
    end
    context 'on' do
      let(:team) { Fabricate(:team, gifs: true) }
      it 'true' do
        expect(app.send(:client).send_gifs?).to be true
      end
    end
    context 'off' do
      let(:team) { Fabricate(:team, gifs: false) }
      it 'false' do
        expect(app.send(:client).send_gifs?).to be false
      end
    end
  end
  context 'aliases' do
    let(:game) { Fabricate(:game, name: 'game', aliases: []) }
    let(:team) { Fabricate(:team, game: game, aliases: %w(t1 t2)) }
    it 'combines game name and team aliases' do
      expect(app.send(:client).aliases).to eq %w(game t1 t2)
    end
  end
  context 'hooks' do
    let(:client) { app.send(:client) }
    let(:user) { Fabricate(:user, team: team) }
    it 'renames user' do
      app.hooks.handlers[:user_change].each do |hook|
        hook.call(client, Hashie::Mash.new(type: 'user_change', user: { id: user.user_id, name: 'updated' }))
      end
      expect(user.reload.user_name).to eq('updated')
    end
    it 'does not touch a user with the same name' do
      allow(User).to receive(:where).and_return([user])
      app.hooks.handlers[:user_change].each do |hook|
        hook.call(client, Hashie::Mash.new(type: 'user_change', user: { id: user.user_id, name: user.user_name }))
      end
      expect(user).to_not receive(:update_attributes!)
    end
  end
end
