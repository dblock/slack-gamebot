require 'spec_helper'

describe SlackGamebot::Commands::Info do
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }
  let(:message_hook) { SlackRubyBot::Hooks::Message.new }
  let(:team) { Fabricate(:team) }
  it 'info' do
    expect(client).to receive(:say).with(channel: 'channel', text: SlackGamebot::INFO)
    message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: "#{SlackRubyBot.config.user} info"))
  end
end
