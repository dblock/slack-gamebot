require 'spec_helper'

describe Match do
  context 'elo' do
    context 'singles' do
      before do
        @match = Fabricate(:match)
      end
      it 'updates elo and tau' do
        expect(@match.challenge.challengers.map(&:elo)).to eq [48]
        expect(@match.challenge.challengers.map(&:tau)).to eq [0.5]
        expect(@match.challenge.challenged.map(&:elo)).to eq [-48]
        expect(@match.challenge.challenged.map(&:tau)).to eq [0.5]
      end
    end
    context 'doubles' do
      before do
        @match = Fabricate(:match, challenge: Fabricate(:doubles_challenge))
        @match.reload
      end
      it 'updates elo and tau' do
        expect(@match.challenge.challengers.map(&:elo)).to eq [48, 48]
        expect(@match.challenge.challengers.map(&:tau)).to eq [0.5, 0.5]
        expect(@match.challenge.challenged.map(&:elo)).to eq [-48, -48]
        expect(@match.challenge.challenged.map(&:tau)).to eq [0.5, 0.5]
      end
    end
    context 'two matches against previous losers' do
      before do
        challenge1 = Fabricate(:doubles_challenge)
        challenge1.accept!(challenge1.challenged.first)
        challenge1.lose!(challenge1.challengers.first)
        challengers = challenge1.challengers
        challenged = [Fabricate(:user), Fabricate(:user)]
        @match = Fabricate(:match, challenge: Fabricate(:challenge, challengers: challengers, challenged: challenged))
        @match.reload
      end
      it 'updates elo and tau' do
        expect(@match.challenge.challengers.map(&:elo)).to eq [5, 5]
        expect(@match.challenge.challengers.map(&:tau)).to eq [1, 1]
        expect(@match.challenge.challenged.map(&:elo)).to eq [-55, -55]
        expect(@match.challenge.challenged.map(&:tau)).to eq [0.5, 0.5]
      end
    end
    context 'two matches against previous winners' do
      before do
        challenge1 = Fabricate(:doubles_challenge)
        challenge1.accept!(challenge1.challenged.first)
        challenge1.lose!(challenge1.challengers.first)
        challengers = challenge1.challenged
        challenged = [Fabricate(:user), Fabricate(:user)]
        @match = Fabricate(:match, challenge: Fabricate(:challenge, challengers: challengers, challenged: challenged))
        @match.reload
      end
      it 'updates elo and tau' do
        expect(@match.challenge.challengers.map(&:elo)).to eq [88, 88]
        expect(@match.challenge.challengers.map(&:tau)).to eq [1, 1]
        expect(@match.challenge.challenged.map(&:elo)).to eq [-41, -41]
        expect(@match.challenge.challenged.map(&:tau)).to eq [0.5, 0.5]
      end
    end
    context 'scores' do
      let(:team) { Fabricate(:team) }
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
      pending 'draw' do
        expect(Match.new(team: team, scores: [[15, 15]])).to be_valid
      end
    end
  end
end
