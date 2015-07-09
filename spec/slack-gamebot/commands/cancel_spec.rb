require 'spec_helper'

describe SlackGamebot::Commands::Cancel, vcr: { cassette_name: 'user_info' } do
  def app
    SlackGamebot::App.new
  end
  context 'challenger' do
    let(:challenger) { Fabricate(:user, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, challengers: [challenger]) }
    it 'cancels a challenge' do
      expect(message: "#{SlackRubyBot.config.user} cancel", user: challenger.user_id, channel: challenge.channel).to respond_with_slack_message(
        "#{challenge.challengers.map(&:user_name).join(' and ')} canceled a challenge against #{challenge.challenged.map(&:user_name).join(' and ')}."
      )
      expect(challenge.reload.state).to eq ChallengeState::CANCELED
    end
  end
  context 'challenged' do
    let(:challenged) { Fabricate(:user, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
    it 'cancels a challenge' do
      expect(message: "#{SlackRubyBot.config.user} cancel", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "#{challenge.challenged.map(&:user_name).join(' and ')} canceled a challenge against #{challenge.challengers.map(&:user_name).join(' and ')}."
      )
      expect(challenge.reload.state).to eq ChallengeState::CANCELED
    end
  end
end
