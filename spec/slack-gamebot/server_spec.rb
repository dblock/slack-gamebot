require 'spec_helper'

describe SlackGamebot::Server do
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
end
