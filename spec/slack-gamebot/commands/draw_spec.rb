require 'spec_helper'

describe SlackGamebot::Commands::Draw, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:challenged) { Fabricate(:user, user_name: 'username') }
  let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
  before do
    challenge.accept!(challenged)
  end
  it 'draw' do
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match is a draw, waiting to hear from #{challenge.challengers.map(&:user_name).and}."
    )
    challenge.reload
    expect(challenge.state).to eq ChallengeState::ACCEPTED
    expect(challenge.draw).to eq challenge.challenged
  end
  it 'draw with a score requires premium subscription' do
    expect(message: "#{SlackRubyBot.config.user} draw 2:2", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Recording scores is now a premium feature, sorry. You can still record games without scores. #{team.upgrade_text}"
    )
    challenge.reload
    expect(challenge.draw.any?).to be false
  end
  context 'premium team' do
    before do
      team.set(premium: true)
    end
    it 'draw with a score' do
      expect(message: "#{SlackRubyBot.config.user} draw 2:2", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match is a draw, waiting to hear from #{challenge.challengers.map(&:user_name).and}. Recorded the score of 2:2."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::ACCEPTED
      expect(challenge.draw).to eq challenge.challenged
      expect(challenge.draw_scores?).to be true
      expect(challenge.draw_scores).to eq [[2, 2]]
    end
    context 'confirmation' do
      before do
        challenge.draw!(challenge.challengers.first)
      end
      it 'confirmed' do
        expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{challenge.challengers.map(&:user_name).and} tied with #{challenge.challenged.map(&:user_name).and}."
        )
        challenge.reload
        expect(challenge.state).to eq ChallengeState::PLAYED
        expect(challenge.draw).to eq challenge.challenged + challenge.challengers
      end
      it 'with score' do
        expect(message: "#{SlackRubyBot.config.user} draw 3:3", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{challenge.challengers.map(&:user_name).and} tied with #{challenge.challenged.map(&:user_name).and} with the score of 3:3."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[3, 3]]
      end
      it 'with invalid score' do
        expect(message: "#{SlackRubyBot.config.user} draw 21:15", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          'In a tie both sides must score the same number of points.'
        )
      end
      it 'draw with scores' do
        expect(message: "#{SlackRubyBot.config.user} draw 21:15 15:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{challenge.challengers.map(&:user_name).and} tied with #{challenge.challenged.map(&:user_name).and} with the scores of 15:21 21:15."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[21, 15], [15, 21]]
      end
    end
  end
  it 'draw already confirmed' do
    challenge.draw!(challenge.challenged.first)
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      "Match is a draw, still waiting to hear from #{challenge.challengers.map(&:user_name).and}."
    )
  end
  it 'does not update a previously lost match' do
    challenge.lose!(challenge.challenged.first)
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      'No challenge to draw!'
    )
  end
  it 'does not update a previously won match' do
    challenge.lose!(challenge.challengers.first)
    expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
      'No challenge to draw!'
    )
  end
end
