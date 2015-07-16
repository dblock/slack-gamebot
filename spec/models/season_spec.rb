require 'spec_helper'

describe Season do
  context 'with challenges' do
    let!(:open_challenge) { Fabricate(:challenge) }
    let!(:matches) { 3.times.map { Fabricate(:match) } }
    let!(:season) { Fabricate(:season) }
    it 'archives challenges' do
      expect(season.challenges.count).to eq 4
    end
    it 'cancels open challenges' do
      expect(open_challenge.reload.state).to eq ChallengeState::CANCELED
    end
    it 'resets users' do
      expect(User.all.detect { |u| u.wins != 0 || u.losses != 0 }).to be nil
    end
    it 'saves user ranks' do
      expect(season.user_ranks.count).to eq 3
    end
    it 'to_s' do
      expect(season.to_s).to eq "#{season.created_at.strftime('%F')}: #{season.send(:winner).user_name}: 1 win, 0 losses (elo: 48), 3 matches, 3 players"
    end
  end
  context 'without challenges' do
    it 'cannot be created' do
      season = Season.new
      expect(season).to_not be_valid
      expect(season.errors.messages).to eq(challenges: ['No matches have been recorded.'])
    end
  end
  context 'current season' do
    let!(:matches) { 3.times.map { Fabricate(:match) } }
    let(:season) { Season.new }
    it 'to_s' do
      expect(season.to_s).to eq "Current: #{season.send(:winner).user_name}: 1 win, 0 losses (elo: 48), 3 matches, 3 players"
    end
  end
end
