require 'spec_helper'

describe Elo do
  describe '#team_elo' do
    it 'is rounded average of elo' do
      expect(Elo.team_elo([User.new(elo: 1)])).to eq 1
      expect(Elo.team_elo([User.new(elo: 1), User.new(elo: 2)])).to eq 1.5
      expect(Elo.team_elo([User.new(elo: 3), User.new(elo: 3), User.new(elo: 4)])).to eq 3.33
    end
  end
end
