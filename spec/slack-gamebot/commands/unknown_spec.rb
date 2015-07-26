require 'spec_helper'

describe SlackRubyBot::Commands::Unknown, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::App.new }
  let(:client) { app.send(:client) }
  it 'invalid command' do
    expect(message: "#{SlackRubyBot.config.user} foobar").to respond_with_slack_message("Sorry <@user>, I don't understand that command!")
  end
  it 'does not respond to sad face' do
    expect(SlackRubyBot::Commands::Base).to_not receive(:send_message)
    SlackGamebot::App.new.send(:message, client, text: ':((')
  end
end
