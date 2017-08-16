require 'spec_helper'

describe SlackGamebot::Commands::Taunt, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, user_name: 'username') }
  let(:opponent) { Fabricate(:user) }
  it 'creates a singles taunt by user name' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} taunt #{opponent.user_name}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.user_name} said that #{opponent.user_name} sucks at ping pong!"
      )
    end
  end
end
