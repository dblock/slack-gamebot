require 'spec_helper'

describe SlackGamebot::Commands::Unregister, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'team' do
    let!(:team) { Fabricate(:team) }
    it 'is a premium feature' do
      expect(message: "#{SlackRubyBot.config.user} unregister", user: 'user').to respond_with_slack_message(
        "This is a premium feature. Upgrade your team to premium for $29.99 a year at https://www.playplay.io/upgrade?team_id=#{team.team_id}&game=#{team.game.name}."
      )
    end
  end
  context 'premium team' do
    let!(:team) { Fabricate(:team, premium: true) }
    it 'requires a captain to unregister someone' do
      Fabricate(:user, captain: true, team: team)
      user = Fabricate(:user)
      expect(message: "#{SlackRubyBot.config.user} unregister #{user.user_name}").to respond_with_slack_message("You're not a captain, sorry.")
    end
    it 'registers, then unregisters a previously unknown user' do
      expect do
        expect(message: "#{SlackRubyBot.config.user} unregister", user: 'user1').to respond_with_slack_message("I've removed <@user1> from the leaderboard.")
      end.to change(::User, :count).by(1)
      expect(User.where(user_id: 'user1').first.registered).to be false
    end
    it 'cannot unregister an unknown user by name' do
      user = Fabricate(:user, team: Fabricate(:team)) # another user in another team
      expect(message: "#{SlackRubyBot.config.user} unregister #{user.user_name}").to respond_with_slack_message("I don't know who #{user.user_name} is! Ask them to _register_.")
    end
    it 'unregisters self' do
      user = Fabricate(:user, user_id: 'user')
      expect(message: "#{SlackRubyBot.config.user} unregister", user: user.user_id).to respond_with_slack_message("I've removed <@user> from the leaderboard.")
      expect(user.reload.registered).to be false
    end
    it 'unregisters self via me' do
      user = Fabricate(:user, user_id: 'user')
      expect(message: "#{SlackRubyBot.config.user} unregister me", user: user.user_id).to respond_with_slack_message("I've removed <@user> from the leaderboard.")
      expect(user.reload.registered).to be false
    end
    it 'unregisters another user' do
      user = Fabricate(:user)
      expect(message: "#{SlackRubyBot.config.user} unregister #{user.user_name}", user: 'user').to respond_with_slack_message("I've removed <@#{user.user_id}> from the leaderboard.")
      expect(user.reload.registered).to be false
    end
    it 'unregisters multiple users' do
      user1 = Fabricate(:user)
      user2 = Fabricate(:user)
      expect(message: "#{SlackRubyBot.config.user} unregister #{user1.user_name} <@#{user2.user_id}>", user: 'user').to respond_with_slack_message(
        "I've removed <@#{user1.user_id}> and <@#{user2.user_id}> from the leaderboard."
      )
      expect(user1.reload.registered).to be false
      expect(user2.reload.registered).to be false
    end
  end
end
