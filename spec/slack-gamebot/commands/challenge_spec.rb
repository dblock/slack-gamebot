require 'spec_helper'

describe SlackGamebot::Commands::Challenge, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:user) { Fabricate(:user, user_name: 'username') }
  let(:opponent) { Fabricate(:user) }
  it 'creates a singles challenge by user id' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge <@#{opponent.user_id}>", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.user_name} challenged #{opponent.user_name} to a match!"
      )
    end.to change(Challenge, :count).by(1)
    challenge = Challenge.last
    expect(challenge.channel).to eq 'pongbot'
    expect(challenge.created_by).to eq user
    expect(challenge.challengers).to eq [user]
    expect(challenge.challenged).to eq [opponent]
  end
  it 'creates a singles challenge by user name' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent.user_name}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.user_name} challenged #{opponent.user_name} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end
  it 'creates a singles challenge by user name case-insensitive' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent.user_name.capitalize}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.user_name} challenged #{opponent.user_name} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end
  it 'requires an opponent' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge", user: user.user_id, channel: 'pongbot').to respond_with_error(
        'Number of teammates (1) and opponents (0) must match.'
      )
    end.to_not change(Challenge, :count)
  end
  it 'does not butcher names with special characters' do
    expect(message: "#{SlackRubyBot.config.user} challenge Jung-hwa", user: user.user_id, channel: 'pongbot').to respond_with_error(
      "I don't know who Jung-hwa is! Ask them to _#{SlackRubyBot.config.user} register_."
    )
  end
end
