require 'spec_helper'

describe SlackGamebot::Commands::Resigned, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'with a challenge' do
    let(:challenged) { Fabricate(:user, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
    before do
      challenge.accept!(challenged)
    end
    it 'resigned' do
      expect(message: "#{SlackRubyBot.config.user} resigned", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challenged.map(&:user_name).and} resigned against #{challenge.challengers.map(&:user_name).and}."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
      expect(challenge.match.resigned?).to be true
    end
    it 'resigned with score requires a premium subscription' do
      expect(message: "#{SlackRubyBot.config.user} resigned 15:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Recording scores is now a premium feature, sorry. You can still record games without scores. #{team.upgrade_text}"
      )
    end
    context 'premium team' do
      before do
        team.set(premium: true)
      end
      it 'resigned with score' do
        expect(message: "#{SlackRubyBot.config.user} resigned 15:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
          'Cannot score when resigning.'
        )
      end
    end
  end
  context 'resigned to' do
    let(:loser) { Fabricate(:user, user_name: 'username') }
    let(:winner) { Fabricate(:user) }
    it 'a player' do
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} resigned to #{winner.user_name}", user: loser.user_id, channel: 'channel').to respond_with_slack_message(
            "Match has been recorded! #{loser.user_name} resigned against #{winner.user_name}."
          )
        end.to_not change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
      expect(match.resigned?).to be true
    end
    it 'two players' do
      winner2 = Fabricate(:user, team: team)
      loser2 = Fabricate(:user, team: team)
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} resigned to #{winner.user_name} #{winner2.user_name} with #{loser2.user_name}", user: loser.user_id, channel: 'pongbot').to respond_with_slack_message(
            "Match has been recorded! #{loser.user_name} and #{loser2.user_name} resigned against #{winner.user_name} and #{winner2.user_name}."
          )
        end.to_not change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner2, winner]
      expect(match.losers).to eq [loser2, loser]
      expect(match.resigned?).to be true
    end
  end
end
