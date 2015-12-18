require 'spec_helper'

describe SlackGamebot::Commands::Register, vcr: { cassette_name: 'user_info' } do
  let(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  it 'registers a new user' do
    expect(message: "#{SlackRubyBot.config.user} register", user: 'user').to respond_with_slack_message("Welcome <@user>! You're ready to play.")
  end
  it 'renames an existing user' do
    Fabricate(:user, user_id: 'user')
    expect(message: "#{SlackRubyBot.config.user} register", user: 'user').to respond_with_slack_message("Welcome back <@user>, I've updated your registration.")
  end
  it 'already registered' do
    Fabricate(:user, user_id: 'user', user_name: 'username')
    expect(message: "#{SlackRubyBot.config.user} register", user: 'user').to respond_with_slack_message("Welcome back <@user>, you're already registered.")
  end
end
