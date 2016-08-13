require 'spec_helper'

describe SlackGamebot::Commands::Lost, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'with an existing challenge' do
    let(:challenged) { Fabricate(:user, user_name: 'username') }
    let!(:challenge) { Fabricate(:challenge, challenged: [challenged]) }
    before do
      challenge.accept!(challenged)
    end
    it 'lost' do
      expect(message: "#{SlackRubyBot.config.user} lost", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and}."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
      winner = challenge.match.winners.first
      loser = challenge.match.losers.first
      expect(winner.elo).to eq 48
      expect(winner.tau).to eq 0.5
      expect(loser.elo).to eq(-48)
      expect(loser.tau).to eq 0.5
    end
    it 'updates existing challenge when lost to' do
      expect(message: "#{SlackRubyBot.config.user} lost to #{challenge.challengers.first.user_name}", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and}."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
    end
    it 'lost with score' do
      expect(message: "#{SlackRubyBot.config.user} lost 15:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and} with the score of 21:15."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[15, 21]]
      expect(challenge.match.resigned?).to be false
    end
    it 'lost with invalid score' do
      expect(message: "#{SlackRubyBot.config.user} lost 21:15", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        'Loser scores must come first.'
      )
    end
    it 'lost with scores' do
      expect(message: "#{SlackRubyBot.config.user} lost 21:15 14:21 5:11", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and} with the scores of 15:21 21:14 11:5."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[21, 15], [14, 21], [5, 11]]
    end
    it 'lost with a crushing score' do
      expect(message: "#{SlackRubyBot.config.user} lost 5:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers.map(&:user_name).and} crushed #{challenge.challenged.map(&:user_name).and} with the score of 21:5."
      )
    end
    it 'lost in a close game' do
      expect(message: "#{SlackRubyBot.config.user} lost 19:21", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers.map(&:user_name).and} narrowly defeated #{challenge.challenged.map(&:user_name).and} with the score of 21:19."
      )
    end
    it 'lost amending scores' do
      challenge.lose!(challenged)
      expect(message: "#{SlackRubyBot.config.user} lost 21:15 14:21 5:11", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match scores have been updated! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and} with the scores of 15:21 21:14 11:5."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[21, 15], [14, 21], [5, 11]]
    end
    it 'does not update a previously lost match' do
      challenge.lose!(challenged, [[11, 21]])
      challenge2 = Fabricate(:challenge, challenged: [challenged])
      challenge2.accept!(challenged)
      expect(message: "#{SlackRubyBot.config.user} lost", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge2.challengers.map(&:user_name).and} defeated #{challenge2.challenged.map(&:user_name).and}."
      )
      challenge.reload
      expect(challenge.match.scores).to eq [[11, 21]]
      challenge2.reload
      expect(challenge2.state).to eq ChallengeState::PLAYED
      expect(challenge2.match.scores).to be nil
    end
    it 'does not update a previously won match' do
      challenge.lose!(challenge.challengers.first, [[11, 21]])
      expect(message: "#{SlackRubyBot.config.user} lost", user: challenged.user_id, channel: challenge.channel).to respond_with_slack_message(
        'No challenge to lose!'
      )
    end
  end
  context 'with an existing unbalanced challenge' do
    let(:challenged1) { Fabricate(:user, user_name: 'username') }
    let(:challenged2) { Fabricate(:user) }
    let(:challenge) { Fabricate(:challenge, challenged: [challenged1, challenged2]) }
    before do
      team.update_attributes!(unbalanced: true)
      challenge.accept!(challenged1)
    end
    it 'lost' do
      expect(message: "#{SlackRubyBot.config.user} lost", user: challenged1.user_id, channel: challenge.channel).to respond_with_slack_message(
        "Match has been recorded! #{challenge.challengers.map(&:user_name).and} defeated #{challenge.challenged.map(&:user_name).and}."
      )
      challenge.reload
      expect(challenge.state).to eq ChallengeState::PLAYED
      expect(challenge.match.winners).to eq challenge.challengers
      expect(challenge.match.losers).to eq challenge.challenged
      winner = challenge.match.winners.first
      loser = challenge.match.losers.first
      expect(winner.elo).to eq 48
      expect(winner.tau).to eq 0.5
      expect(loser.elo).to eq(-24)
      expect(loser.tau).to eq 0.5
    end
  end
  context 'lost to' do
    let(:loser) { Fabricate(:user, user_name: 'username') }
    let(:winner) { Fabricate(:user) }
    it 'a player' do
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} lost to #{winner.user_name}", user: loser.user_id, channel: 'channel').to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} defeated #{loser.user_name}."
          )
        end.to_not change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
    end
    it 'two players' do
      winner2 = Fabricate(:user, team: team)
      loser2 = Fabricate(:user, team: team)
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} lost to #{winner.user_name} #{winner2.user_name} with #{loser2.user_name}", user: loser.user_id, channel: 'pongbot').to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} and #{winner2.user_name} defeated #{loser.user_name} and #{loser2.user_name}."
          )
        end.to_not change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner2, winner]
      expect(match.losers).to eq [loser2, loser]
    end
    it 'two players with scores' do
      winner2 = Fabricate(:user, team: team)
      loser2 = Fabricate(:user, team: team)
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} lost to #{winner.user_name} #{winner2.user_name} with #{loser2.user_name} 15:21", user: loser.user_id, channel: 'pongbot').to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} and #{winner2.user_name} defeated #{loser.user_name} and #{loser2.user_name} with the score of 21:15."
          )
        end.to_not change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner2, winner]
      expect(match.losers).to eq [loser2, loser]
      expect(match.scores).to eq [[15, 21]]
    end
    it 'with score' do
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} lost to #{winner.user_name} 15:21", user: loser.user_id, channel: 'channel').to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} defeated #{loser.user_name} with the score of 21:15."
          )
        end.to_not change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
      expect(match.scores).to eq [[15, 21]]
      expect(match.resigned?).to be false
    end
    it 'with scores' do
      expect do
        expect do
          expect(message: "#{SlackRubyBot.config.user} lost to #{winner.user_name} 21:15 14:21 5:11", user: loser.user_id, channel: 'channel').to respond_with_slack_message(
            "Match has been recorded! #{winner.user_name} defeated #{loser.user_name} with the scores of 15:21 21:14 11:5."
          )
        end.to_not change(Challenge, :count)
      end.to change(Match, :count).by(1)
      match = Match.asc(:_id).last
      expect(match.winners).to eq [winner]
      expect(match.losers).to eq [loser]
      expect(match.scores).to eq [[21, 15], [14, 21], [5, 11]]
      expect(match.resigned?).to be false
    end
  end
end
