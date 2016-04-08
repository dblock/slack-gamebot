require 'spec_helper'

describe Score do
  context '#points' do
    it 'returns losing and winning points for one score' do
      expect(Score.points([[15, 21]])).to eq [15, 21]
    end
    it 'returns losing and winning points for mulitple scores' do
      expect(Score.points([[15, 21], [11, 9]])).to eq [26, 30]
    end
  end
  context '#valid?' do
    it 'loser first' do
      expect(Score.valid?([[15, 21]])).to be true
    end
    it 'loser first with 3 scores' do
      expect(Score.valid?([[15, 21], [21, 5], [3, 11]])).to be true
    end
    it 'winner first' do
      expect(Score.valid?([[21, 15]])).to be false
    end
    it 'winner first with 3 scores' do
      expect(Score.valid?([[21, 15], [5, 21], [11, 3]])).to be false
    end
  end
  context '#tie?' do
    it 'tie with the same number of points' do
      expect(Score.tie?([[15, 15]])).to be true
    end
    it 'tie with different number of points' do
      expect(Score.tie?([[21, 15]])).to be false
    end
    it 'tie with multiple same number of points' do
      expect(Score.tie?([[15, 14], [14, 15]])).to be true
    end
    it 'tie with multiple different number of points' do
      expect(Score.tie?([[21, 15], [15, 14]])).to be false
    end
  end
  context '#parse' do
    it 'nil' do
      expect(Score.parse(nil)).to be nil
    end
    it 'x:y' do
      expect { Score.parse('x:y') }.to raise_error SlackGamebot::Error, 'Invalid score: x:y, invalid value for Integer(): "x".'
    end
    it '-1:5' do
      expect { Score.parse('-1:5') }.to raise_error SlackGamebot::Error, 'Invalid score: -1:5, points must be greater or equal to zero.'
    end
    it '21:0' do
      expect(Score.parse('21:0')).to eq [[21, 0]]
    end
    it '5:3' do
      expect(Score.parse('5:3')).to eq [[5, 3]]
    end
    it '5-3' do
      expect(Score.parse('5-3')).to eq [[5, 3]]
    end
    it '5:3 9:11' do
      expect(Score.parse('5:3 9:11')).to eq [[5, 3], [9, 11]]
    end
    it '5:3, 9:11.' do
      expect(Score.parse('5:3, 9:11.')).to eq [[5, 3], [9, 11]]
    end
  end
end
