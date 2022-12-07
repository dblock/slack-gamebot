require 'spec_helper'

describe SlackGamebot::Commands::Draw, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }
  context 'with a challenge' do
    let(:challenged) { Fabricate(:user, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
    before do
      challenge.accept!(challenged)
    end
    it 'draw' do
      expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match is a draw, waiting to hear from #{challenge.challengers.map(&:display_name).and}."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::DRAWN
      expect(challenge.draw).to eq challenge.challenged
    end
    it 'draw with a score' do
      expect(message: "#{SlackRubyBot.config.user} draw 2:2", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match is a draw, waiting to hear from #{challenge.challengers.map(&:display_name).and}. Recorded the score of 2:2."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::DRAWN
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
          "Match has been recorded! #{challenge.challengers.map(&:display_name).and} tied with #{challenge.challenged.map(&:display_name).and}."
        )
        challenge.reload
        expect(challenge.state).to eq ChallengeState::PLAYED
        expect(challenge.draw).to eq challenge.challenged + challenge.challengers
      end
      it 'with score' do
        expect(message: "#{SlackRubyBot.config.user} draw 3:3", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{challenge.challengers.map(&:display_name).and} tied with #{challenge.challenged.map(&:display_name).and} with the score of 3:3."
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
          "Match has been recorded! #{challenge.challengers.map(&:display_name).and} tied with #{challenge.challenged.map(&:display_name).and} with the scores of 15:21 21:15."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[21, 15], [15, 21]]
      end
    end
    it 'draw already confirmed' do
      challenge.draw!(challenge.challenged.first)
      expect(message: "#{SlackRubyBot.config.user} draw", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match is a draw, still waiting to hear from #{challenge.challengers.map(&:display_name).and}."
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
  context 'without a challenge' do
    let(:winner) { Fabricate(:user) }
    let(:loser) { Fabricate(:user, user_name: 'username') }
    it 'draw to' do
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} draw to #{winner.user_name}", user: loser.user_id, channel: 'channel').to respond_with_slack_message(
            "Match is a draw, waiting to hear from #{winner.user_name}."
          )
        end.to change(Challenge, :count).by(1)
      end.to_not change(Match, :count)
      challenge = Challenge.desc(:_id).first
      expect(challenge.state).to eq ChallengeState::DRAWN
      expect(challenge.draw).to eq [loser]
    end
    it 'draw with a score' do
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} draw to #{winner.user_name} 2:2", user: loser.user_id, channel: 'channel').to respond_with_slack_message(
            "Match is a draw, waiting to hear from #{winner.user_name}. Recorded the score of 2:2."
          )
        end.to change(Challenge, :count).by(1)
      end.to_not change(Match, :count)
      challenge = Challenge.desc(:_id).first
      expect(challenge.state).to eq ChallengeState::DRAWN
      expect(challenge.draw).to eq [loser]
      expect(challenge.draw_scores?).to be true
      expect(challenge.draw_scores).to eq [[2, 2]]
    end
    context 'confirmation' do
      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:users_info).and_return(nil)
      end
      let!(:challenge) do
        Challenge.create!(
          team: loser.team, channel: 'channel',
          created_by: loser, updated_by: loser,
          challengers: [loser], challenged: [winner],
          draw: [loser], draw_scores: [],
          state: ChallengeState::DRAWN
        )
      end
      it 'still waiting' do
        expect(message: "#{SlackRubyBot.config.user} draw", user: loser.user_id, channel: 'channel').to respond_with_slack_message(
          "Match is a draw, still waiting to hear from #{winner.user_name}."
        )
      end
      it 'confirmed' do
        expect(message: "#{SlackRubyBot.config.user} draw", user: winner.user_id, channel: 'channel').to respond_with_slack_message(
          "Match has been recorded! #{loser.user_name} tied with #{winner.user_name}."
        )
        challenge.reload
        expect(challenge.state).to eq ChallengeState::PLAYED
        expect(challenge.draw).to eq [loser, winner]
      end
      it 'with score' do
        expect(message: "#{SlackRubyBot.config.user} draw 3:3", user: winner.user_id, channel: 'channel').to respond_with_slack_message(
          "Match has been recorded! #{loser.user_name} tied with #{winner.user_name} with the score of 3:3."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[3, 3]]
      end
      it 'with invalid score' do
        expect(message: "#{SlackRubyBot.config.user} draw 21:15", user: winner.user_id, channel: 'channel').to respond_with_slack_message(
          'In a tie both sides must score the same number of points.'
        )
      end
      it 'draw with scores' do
        expect(message: "#{SlackRubyBot.config.user} draw 21:15 15:21", user: winner.user_id, channel: challenge.channel).to respond_with_slack_message(
          "Match has been recorded! #{loser.user_name} tied with #{winner.user_name} with the scores of 15:21 21:15."
        )
        challenge.reload
        expect(challenge.match.scores).to eq [[21, 15], [15, 21]]
      end
    end
  end
end
