require 'spec_helper'

describe SlackGamebot::Commands::Promote, vcr: { cassette_name: 'user_info' } do
  let(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:user) { Fabricate(:user, team: team, user_name: 'username', is_admin: true) }
  it 'gives help' do
    expect(message: "#{SlackRubyBot.config.user} promote", user: user.user_id).to respond_with_slack_message(
      'Try _promote @someone_.'
    )
  end
  it 'promotes another user' do
    another_user = Fabricate(:user, team: team)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{another_user.user_name} has been promoted to admin."
    )
    expect(another_user.reload.is_admin?).to be true
  end
  it 'cannot promote self' do
    expect(message: "#{SlackRubyBot.config.user} promote username", user: user.user_id).to respond_with_slack_message(
      "#{user.user_name} is already an admin."
    )
    expect(user.reload.is_admin?).to be true
  end
  it 'promotes multiple users' do
    another_user1 = Fabricate(:user, team: team)
    another_user2 = Fabricate(:user, team: team)
    another_user3 = Fabricate(:user, team: team)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user1.user_name} #{another_user2.user_name} #{another_user3.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{another_user1.user_name}, #{another_user2.user_name} and #{another_user3.user_name} have been promoted to admin."
    )
    expect(another_user1.reload.is_admin?).to be true
    expect(another_user2.reload.is_admin?).to be true
    expect(another_user3.reload.is_admin?).to be true
  end
  it 'cannot promote another admin' do
    another_user = Fabricate(:user, team: team, is_admin: true)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
      "#{another_user.user_name} is already an admin."
    )
    expect(another_user.reload.is_admin?).to be true
  end
  it 'cannot promote when not an admin' do
    user.demote!
    another_user = Fabricate(:user, team: team, is_admin: true)
    expect(message: "#{SlackRubyBot.config.user} promote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
      "You're not an admin, sorry."
    )
    expect(user.reload.is_admin?).to be false
  end
end
