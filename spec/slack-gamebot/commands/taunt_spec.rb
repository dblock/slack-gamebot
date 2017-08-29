require 'spec_helper'

describe SlackGamebot::Commands::Taunt, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team, name: 'teamname') }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, user_name: 'username') }
  it 'taunts one person by user id' do
    victim = Fabricate(:user, team: team)
        expect(message: "#{SlackRubyBot.config.user} taunt <@#{victim.user_id}>", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} says that #{victim.user_name} sucks at #{client.owner.game.name}!")
  end
  it 'taunts one person by user name' do
    victim = Fabricate(:user, team: team)
       expect(message: "#{SlackRubyBot.config.user} taunt #{victim.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} says that #{victim.user_name} sucks at #{client.owner.game.name}!")
  end
end
