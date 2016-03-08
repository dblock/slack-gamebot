require 'spec_helper'

describe SlackGamebot::Service do
  let(:team) { Fabricate(:team) }
  let(:server) { SlackGamebot::Server.new(team: team) }
  let(:services) { SlackGamebot::Service.instance_variable_get(:@services) }
  before do
    allow(SlackGamebot::Server).to receive(:new).with(team: team).and_return(server)
    allow(EM).to receive(:next_tick).and_yield
    allow(EM).to receive(:defer).and_yield
    allow(server).to receive(:stop!)
  end
  after do
    SlackGamebot::Service.reset!
  end
  it 'starts a team' do
    expect(server).to receive(:start_async)
    SlackGamebot::Service.start!(team)
  end
  context 'started team' do
    before do
      allow(server).to receive(:start_async)
      SlackGamebot::Service.start!(team)
    end
    it 'registers team service' do
      expect(services.size).to eq 1
      expect(services[team.token]).to eq server
    end
    it 'removes team service' do
      SlackGamebot::Service.stop!(team)
      expect(services.size).to eq 0
    end
    it 'deactivates a team' do
      SlackGamebot::Service.deactivate!(team)
      expect(team.reload.active).to be false
      expect(services.size).to eq 0
    end
  end
end
