require 'spec_helper'

describe SlackGamebot::Commands::Demote, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  context 'captain' do
    let(:user) { Fabricate(:user, team: team, user_name: 'username', captain: true) }
    it 'demotes self' do
      another_user = Fabricate(:user, team: team, captain: true)
      expect(message: "#{SlackRubyBot.config.user} demote me", user: user.user_id).to respond_with_slack_message(
        "#{user.user_name} is no longer captain."
      )
      expect(another_user.reload.captain?).to be true
    end
    it 'cannot demote the last captain' do
      expect(message: "#{SlackRubyBot.config.user} demote me", user: user.user_id).to respond_with_slack_message(
        "You cannot demote yourself, you're the last captain. Promote someone else first."
      )
    end
    it 'cannot demote another captain' do
      another_user = Fabricate(:user, team: team, captain: true)
      expect(message: "#{SlackRubyBot.config.user} demote #{another_user.user_name}", user: user.user_id).to respond_with_slack_message(
        'You can only demote yourself, try _demote me_.'
      )
      expect(another_user.reload.captain?).to be true
    end
  end
  context 'not captain' do
    let!(:captain) { Fabricate(:user, team: team, captain: true) }
    let(:user) { Fabricate(:user, team: team, user_name: 'username') }
    it 'cannot demote' do
      expect(message: "#{SlackRubyBot.config.user} demote me", user: user.user_id).to respond_with_slack_message(
        "You're not a captain, sorry."
      )
      expect(user.reload.captain?).to be false
    end
  end
end
