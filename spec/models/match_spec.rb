require 'spec_helper'

describe Match do
  context '#to_s' do
    let(:match) { Fabricate(:match) }
    it 'displays match' do
      expect(match.to_s).to eq "#{match.winners.first.user_name} defeated #{match.losers.first.user_name} with #{Score.scores_to_string(match.scores)}"
    end
    context 'unregistered users' do
      before do
        match.winners.first.unregister!
      end
      it 'removes user name' do
        expect(match.to_s).to eq "<unregistered> defeated #{match.losers.first.user_name} with #{Score.scores_to_string(match.scores)}"
      end
    end
    context 'user with nickname' do
      before do
        match.winners.first.update_attributes!(nickname: 'bob')
      end
      it 'rewrites user name' do
        expect(match.to_s).to eq "bob defeated #{match.losers.first.user_name} with #{Score.scores_to_string(match.scores)}"
      end
    end
  end
  context 'elo' do
    context 'singles' do
      let(:match) { Fabricate(:match) }
      it 'updates elo and tau' do
        expect(match.winners.map(&:elo)).to eq [48]
        expect(match.winners.map(&:tau)).to eq [0.5]
        expect(match.losers.map(&:elo)).to eq [-48]
        expect(match.losers.map(&:tau)).to eq [0.5]
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [1]
        expect(match.winners.map(&:losing_streak)).to eq [0]
        expect(match.losers.map(&:winning_streak)).to eq [0]
        expect(match.losers.map(&:losing_streak)).to eq [1]
      end
    end
    context 'singles tied' do
      let(:match) { Fabricate(:match, tied: true) }
      it 'updates elo and tau' do
        expect(match.winners.map(&:elo)).to eq [0.0]
        expect(match.winners.map(&:tau)).to eq [0.5]
        expect(match.losers.map(&:elo)).to eq [0.0]
        expect(match.losers.map(&:tau)).to eq [0.5]
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [0]
        expect(match.winners.map(&:losing_streak)).to eq [0]
        expect(match.losers.map(&:winning_streak)).to eq [0]
        expect(match.losers.map(&:losing_streak)).to eq [0]
      end
    end
    context 'two consecutive losses' do
      let!(:match) { Fabricate(:match) }
      before do
        Fabricate(:match, winners: match.winners, losers: match.losers)
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [2]
        expect(match.winners.map(&:losing_streak)).to eq [0]
        expect(match.losers.map(&:winning_streak)).to eq [0]
        expect(match.losers.map(&:losing_streak)).to eq [2]
      end
    end
    context 'three consecutive losses, then a break for losers preserves losing streak' do
      let!(:match) { Fabricate(:match) }
      before do
        2.times { Fabricate(:match, winners: match.winners, losers: match.losers) }
        Fabricate(:match, winners: match.losers)
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [3]
        expect(match.winners.map(&:losing_streak)).to eq [0]
        expect(match.losers.map(&:winning_streak)).to eq [1]
        expect(match.losers.map(&:losing_streak)).to eq [3]
      end
    end
    context 'doubles' do
      let(:match) { Fabricate(:match, challenge: Fabricate(:doubles_challenge)) }
      it 'updates elo and tau' do
        expect(match.winners.map(&:elo)).to eq [48, 48]
        expect(match.winners.map(&:tau)).to eq [0.5, 0.5]
        expect(match.losers.map(&:elo)).to eq [-48, -48]
        expect(match.losers.map(&:tau)).to eq [0.5, 0.5]
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [1, 1]
        expect(match.winners.map(&:losing_streak)).to eq [0, 0]
        expect(match.losers.map(&:winning_streak)).to eq [0, 0]
        expect(match.losers.map(&:losing_streak)).to eq [1, 1]
      end
    end
    context 'two matches against previous losers' do
      let(:challenge1) { Fabricate(:doubles_challenge) }
      let(:challengers) { challenge1.challengers }
      let(:challenged) { [Fabricate(:user), Fabricate(:user)] }
      let(:match) { Fabricate(:match, challenge: Fabricate(:challenge, challengers: challengers, challenged: challenged)) }
      before do
        challenge1.accept!(challenge1.challenged.first)
        challenge1.lose!(challenge1.challengers.first)
      end
      it 'updates elo and tau' do
        expect(match.winners.map(&:elo)).to eq [5, 5]
        expect(match.winners.map(&:tau)).to eq [1, 1]
        expect(match.losers.map(&:elo)).to eq [-55, -55]
        expect(match.losers.map(&:tau)).to eq [0.5, 0.5]
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [1, 1]
        expect(match.winners.map(&:losing_streak)).to eq [1, 1]
        expect(match.losers.map(&:winning_streak)).to eq [0, 0]
        expect(match.losers.map(&:losing_streak)).to eq [1, 1]
      end
    end
    context 'a tie against previous losers' do
      let(:challenge1) { Fabricate(:doubles_challenge) }
      let(:challengers) { challenge1.challengers }
      let(:challenged) { [Fabricate(:user), Fabricate(:user)] }
      let(:match) { Fabricate(:match, challenge: Fabricate(:challenge, challengers: challengers, challenged: challenged), tied: true) }
      before do
        challenge1.accept!(challenge1.challenged.first)
        challenge1.lose!(challenge1.challengers.first)
      end
      it 'updates elo and tau' do
        expect(match.winners.map(&:elo)).to eq [-21, -21]
        expect(match.winners.map(&:tau)).to eq [1, 1]
        expect(match.losers.map(&:elo)).to eq [-27, -27]
        expect(match.losers.map(&:tau)).to eq [0.5, 0.5]
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [0, 0]
        expect(match.winners.map(&:losing_streak)).to eq [1, 1]
        expect(match.losers.map(&:winning_streak)).to eq [0, 0]
        expect(match.losers.map(&:losing_streak)).to eq [0, 0]
      end
    end
    context 'a tie against previous winners' do
      let(:challenge1) { Fabricate(:doubles_challenge) }
      let(:challengers) { challenge1.challengers }
      let(:challenged) { [Fabricate(:user), Fabricate(:user)] }
      let(:match) { Fabricate(:match, challenge: Fabricate(:challenge, challengers: challengers, challenged: challenged), tied: true) }
      before do
        challenge1.accept!(challenge1.challenged.first)
        challenge1.lose!(challenge1.challenged.first)
      end
      it 'updates elo and tau' do
        expect(match.winners.map(&:elo)).to eq [68, 68]
        expect(match.winners.map(&:tau)).to eq [1, 1]
        expect(match.losers.map(&:elo)).to eq [-20, -20]
        expect(match.losers.map(&:tau)).to eq [0.5, 0.5]
      end
      it 'updates streaks' do
        expect(match.winners.map(&:winning_streak)).to eq [1, 1]
        expect(match.winners.map(&:losing_streak)).to eq [0, 0]
        expect(match.losers.map(&:winning_streak)).to eq [0, 0]
        expect(match.losers.map(&:losing_streak)).to eq [0, 0]
      end
    end
    context 'two matches against previous winners' do
      let(:challenge1) { Fabricate(:doubles_challenge) }
      let(:challengers) { challenge1.challenged }
      let(:challenged) { [Fabricate(:user), Fabricate(:user)] }
      let(:match) { Fabricate(:match, challenge: Fabricate(:challenge, challengers: challengers, challenged: challenged)) }
      before do
        challenge1.accept!(challenge1.challenged.first)
        challenge1.lose!(challenge1.challengers.first)
      end
      it 'updates elo and tau' do
        expect(match.winners.map(&:elo)).to eq [88, 88]
        expect(match.winners.map(&:tau)).to eq [1, 1]
        expect(match.losers.map(&:elo)).to eq [-41, -41]
        expect(match.losers.map(&:tau)).to eq [0.5, 0.5]
      end
    end
    context 'scores' do
      let!(:team) { Fabricate(:team) }
      it 'loser first' do
        expect(Match.new(team: team, scores: [[15, 21]])).to be_valid
      end
      it 'loser first with 3 scores' do
        expect(Match.new(team: team, scores: [[15, 21], [21, 5], [3, 11]])).to be_valid
      end
      it 'winner first' do
        expect(Match.new(team: team, scores: [[21, 15]])).to_not be_valid
      end
      it 'winner first with 3 scores' do
        expect(Match.new(team: team, scores: [[21, 15], [5, 21], [11, 3]])).to_not be_valid
      end
      it 'draw' do
        expect(Match.new(team: team, tied: true, scores: [[15, 15]])).to be_valid
      end
    end
  end
end
