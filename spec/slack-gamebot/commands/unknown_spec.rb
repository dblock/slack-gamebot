require 'spec_helper'

describe SlackRubyBot::Commands::Unknown, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }
  let(:message_hook) { SlackRubyBot::Hooks::Message.new }

  it 'invalid command' do
    expect(message: "#{SlackRubyBot.config.user} foobar").to respond_with_slack_message("Sorry <@user>, I don't understand that command!")
  end

  it 'does not respond to sad face' do
    expect(SlackRubyBot::Commands::Base).not_to receive(:send_message)
    message_hook.call(client, Hashie::Mash.new(text: ':(('))
  end
end
