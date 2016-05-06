require 'spec_helper'

describe SlackGamebot::Commands::Help do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:message_hook) { SlackRubyBot::Hooks::Message.new }
  it 'help' do
    expect(client).to receive(:say).with(channel: 'channel', text: [SlackGamebot::Commands::Help::HELP, SlackGamebot::INFO].join("\n"))
    expect(client).to receive(:say).with(channel: 'channel', gif: 'help')
    message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: "#{SlackRubyBot.config.user} help"))
  end
end
