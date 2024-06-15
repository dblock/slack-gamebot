require 'spec_helper'

describe SlackGamebot::Commands::Challenges, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, user_name: 'username') }

  context 'with challenges' do
    let!(:challenge_proposed) { Fabricate(:challenge) }
    let!(:challenge_canceled) { Fabricate(:canceled_challenge) }
    let!(:challenge_declined) { Fabricate(:declined_challenge) }
    let!(:challenge_accepted) { Fabricate(:accepted_challenge) }
    let!(:challenge_played) { Fabricate(:played_challenge) }

    it 'displays a proposed and accepted challenges' do
      expect(message: "#{SlackRubyBot.config.user} challenges", user: user.user_id, channel: challenge_proposed.channel).to respond_with_slack_message(
        "a challenge between #{challenge_proposed.challengers.map(&:display_name).and} and #{challenge_proposed.challenged.map(&:display_name).and} was proposed just now\n" \
        "a challenge between #{challenge_accepted.challengers.map(&:display_name).and} and #{challenge_accepted.challenged.map(&:display_name).and} was accepted just now"
      )
    end
  end

  context 'without challenges' do
    it 'displays all challenges have been played' do
      expect(message: "#{SlackRubyBot.config.user} challenges", user: user.user_id, channel: 'channel').to respond_with_slack_message(
        'All the challenges have been played.'
      )
    end
  end
end
