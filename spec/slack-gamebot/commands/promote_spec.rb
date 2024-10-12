require 'spec_helper'

describe SlackGamebot::Commands::Promote, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, team:, user_name: 'username', captain: true) }

  it 'gives help' do
    expect(message: "#{SlackRubyBot.config.user} promote", user: user.user_id).to respond_with_slack_message(
      'Try _promote @someone_.'
    )
  end

  it 'promotes another user' do
    another_user = Fabricate(:user, team:)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{another_user.user_name} has been promoted to captain."
    )
    expect(another_user.reload.captain?).to be true
  end

  it 'cannot promote self' do
    expect(message: "#{SlackRubyBot.config.user} promote username", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} is already a captain."
    )
    expect(user.reload.captain?).to be true
  end

  it 'promotes multiple users' do
    another_user1 = Fabricate(:user, team:)
    another_user2 = Fabricate(:user, team:)
    another_user3 = Fabricate(:user, team:)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user1.user_name} #{another_user2.user_name} #{another_user3.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{another_user1.user_name}, #{another_user2.user_name} and #{another_user3.user_name} have been promoted to captain."
    )
    expect(another_user1.reload.captain?).to be true
    expect(another_user2.reload.captain?).to be true
    expect(another_user3.reload.captain?).to be true
  end

  it 'cannot promote another captain' do
    another_user = Fabricate(:user, team:, captain: true)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{another_user.user_name} is already a captain."
    )
    expect(another_user.reload.captain?).to be true
  end

  it 'cannot promote when not a captain' do
    user.demote!
    another_user = Fabricate(:user, team:, captain: true)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
      "You're not a captain, sorry."
    )
    expect(user.reload.captain?).to be false
  end
end
