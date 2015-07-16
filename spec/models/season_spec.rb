require 'spec_helper'

describe Season do
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
    expect(season.user_ranks.count).to eq User.count
  end
end
