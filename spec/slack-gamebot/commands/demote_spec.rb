require 'spec_helper'

describe SlackGamebot::Commands::Demote, vcr: { cassette_name: 'user_info' } do
  let(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  context 'admin' do
    let(:user) { Fabricate(:user, team: team, user_name: 'username', is_admin: true) }
    it 'demotes self' do
      another_user = Fabricate(:user, team: team, is_admin: true)
      expect(message: "#{SlackRubyBot.config.user} demote me", user: user.user_id).to respond_with_slack_message(
        "#{user.user_name} is no longer admin."
      )
      expect(another_user.reload.is_admin?).to be true
    end
    it 'cannot demote the last admin' do
      expect(message: "#{SlackRubyBot.config.user} demote me", user: user.user_id).to respond_with_slack_message(
        "You cannot demote yourself, you're the last admin. Promote someone else first."
      )
    end
    it 'cannot demote another admin' do
      another_user = Fabricate(:user, team: team, is_admin: true)
      expect(message: "#{SlackRubyBot.config.user} demote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
        'You can only demote yourself, try _demote me_.'
      )
      expect(another_user.reload.is_admin?).to be true
    end
  end
  context 'not admin' do
    let!(:admin) { Fabricate(:user, team: team, is_admin: true) }
    let(:user) { Fabricate(:user, team: team, user_name: 'username') }
    it 'cannot demote' do
      expect(message: "#{SlackRubyBot.config.user} demote me", user: user.user_id).to respond_with_slack_message(
        "You're not an admin, sorry."
      )
      expect(user.reload.is_admin?).to be false
    end
  end
end
