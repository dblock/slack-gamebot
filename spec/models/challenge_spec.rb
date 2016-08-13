require 'spec_helper'

describe Challenge do
  context '#to_s' do
    let(:challenge) { Fabricate(:challenge) }
    it 'displays challenge' do
      expect(challenge.to_s).to eq "a challenge between #{challenge.challengers.first.user_name} and #{challenge.challenged.first.user_name}"
    end
    context 'unregistered users' do
      before do
        challenge.challengers.first.unregister!
      end
      it 'removes user name' do
        expect(challenge.to_s).to eq "a challenge between <unregistered> and #{challenge.challenged.first.user_name}"
      end
    end
    context 'users with nickname' do
      before do
        challenge.challengers.first.update_attributes!(nickname: 'bob')
      end
      it 'rewrites user name' do
        expect(challenge.to_s).to eq "a challenge between bob and #{challenge.challenged.first.user_name}"
      end
    end
  end
  context 'find_by_user' do
    let(:challenge) { Fabricate(:challenge) }
    it 'finds a challenge by challenger' do
      challenge.challengers.each do |challenger|
        expect(Challenge.find_by_user(challenge.team, challenge.channel, challenger)).to eq challenge
      end
    end
    it 'finds a challenge by challenged' do
      challenge.challenged.each do |challenger|
        expect(Challenge.find_by_user(challenge.team, challenge.channel, challenger)).to eq challenge
      end
    end
    it 'does not find a challenge on another channel' do
      expect(Challenge.find_by_user(challenge.team, 'another', challenge.challengers.first)).to be nil
    end
  end
  context '#split_teammates_and_opponents', vcr: { cassette_name: 'user_info' } do
    let!(:challenger) { Fabricate(:user) }
    it 'splits a single challenge' do
      opponent = Fabricate(:user, user_name: 'username')
      challengers, opponents = Challenge.split_teammates_and_opponents(challenger.team, challenger, ['username'])
      expect(challengers).to eq([challenger])
      expect(opponents).to eq([opponent])
    end
    it 'splits a double challenge' do
      teammate = Fabricate(:user)
      opponent1 = Fabricate(:user, user_name: 'username')
      opponent2 = Fabricate(:user)
      challengers, opponents = Challenge.split_teammates_and_opponents(challenger.team, challenger, ['username', opponent2.slack_mention, 'with', teammate.slack_mention])
      expect(challengers).to eq([challenger, teammate])
      expect(opponents).to eq([opponent1, opponent2])
    end
    it 'requires known opponents' do
      expect do
        Challenge.split_teammates_and_opponents(challenger.team, challenger, ['username'])
      end.to raise_error SlackGamebot::Error, "I don't know who username is! Ask them to _register_."
    end
  end
  context '#create_from_teammates_and_opponents!' do
    let!(:challenger) { Fabricate(:user) }
    let(:teammate) { Fabricate(:user) }
    let(:opponent) { Fabricate(:user) }
    it 'requires an opponent' do
      expect do
        Challenge.create_from_teammates_and_opponents!(challenger.team, 'channel', challenger, [])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(1\) and opponents \(0\) must match./
    end
    it 'requires the same number of opponents' do
      expect do
        Challenge.create_from_teammates_and_opponents!(challenger.team, 'channel', challenger, [opponent.slack_mention, 'with', teammate.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(2\) and opponents \(1\) must match./
    end
    context 'with unbalanced option enabled' do
      before do
        challenger.team.update_attributes!(unbalanced: true)
      end
      it 'requires an opponent' do
        expect do
          Challenge.create_from_teammates_and_opponents!(challenger.team, 'channel', challenger, [])
        end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(1\) and opponents \(0\) must match./
      end
      it 'does not requires the same number of opponents' do
        expect do
          Challenge.create_from_teammates_and_opponents!(challenger.team, 'channel', challenger, [opponent.slack_mention, 'with', teammate.slack_mention])
        end.to_not raise_error
      end
    end
    it 'requires another opponent' do
      expect do
        Challenge.create_from_teammates_and_opponents!(challenger.team, 'channel', challenger, [challenger.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /#{challenger.user_name} cannot play against themselves./
    end
    it 'uniques opponents mentioned multiple times' do
      expect do
        Challenge.create_from_teammates_and_opponents!(challenger.team, 'channel', challenger, [opponent.slack_mention, opponent.slack_mention, 'with', teammate.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(2\) and opponents \(1\) must match./
    end
    context 'with another singles proposed challenge' do
      let(:challenge) { Fabricate(:challenge) }
      it 'cannot create a duplicate challenge for the challenger' do
        existing_challenger = challenge.challengers.first
        expect do
          Challenge.create_from_teammates_and_opponents!(challenger.team, challenge.channel, challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
      it 'cannot create a duplicate challenge for the challenge' do
        existing_challenger = challenge.challenged.first
        expect do
          Challenge.create_from_teammates_and_opponents!(challenger.team, challenge.channel, challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
    end
    context 'with another doubles proposed challenge' do
      let(:challenge) { Fabricate(:challenge, challengers: [Fabricate(:user), Fabricate(:user)], challenged: [Fabricate(:user), Fabricate(:user)]) }
      it 'cannot create a duplicate challenge for the challenger' do
        existing_challenger = challenge.challengers.last
        expect do
          Challenge.create_from_teammates_and_opponents!(challenger.team, challenge.channel, challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
    end
  end
  context '#accept!' do
    let(:challenge) { Fabricate(:challenge) }
    it 'can be accepted' do
      accepted_by = challenge.challenged.first
      challenge.accept!(accepted_by)
      expect(challenge.updated_by).to eq accepted_by
      expect(challenge.state).to eq ChallengeState::ACCEPTED
    end
    it 'requires accepted_by' do
      challenge.state = ChallengeState::ACCEPTED
      expect(challenge).to_not be_valid
    end
    it 'cannot be accepted by another player' do
      expect do
        challenge.accept!(challenge.challengers.first)
      end.to raise_error Mongoid::Errors::Validations, /Only #{challenge.challenged.map(&:user_name).or} can accept this challenge./
    end
    it 'cannot be accepted twice' do
      accepted_by = challenge.challenged.first
      challenge.accept!(accepted_by)
      expect do
        challenge.accept!(accepted_by)
      end.to raise_error SlackGamebot::Error, /Challenge has already been accepted./
    end
  end
  context '#decline!' do
    let(:challenge) { Fabricate(:challenge) }
    it 'can be declined' do
      declined_by = challenge.challenged.first
      challenge.decline!(declined_by)
      expect(challenge.updated_by).to eq declined_by
      expect(challenge.state).to eq ChallengeState::DECLINED
    end
    it 'requires declined_by' do
      challenge.state = ChallengeState::DECLINED
      expect(challenge).to_not be_valid
    end
    it 'cannot be declined by another player' do
      expect do
        challenge.decline!(challenge.challengers.first)
      end.to raise_error Mongoid::Errors::Validations, /Only #{challenge.challenged.map(&:user_name).or} can decline this challenge./
    end
    it 'cannot be declined twice' do
      declined_by = challenge.challenged.first
      challenge.decline!(declined_by)
      expect do
        challenge.decline!(declined_by)
      end.to raise_error SlackGamebot::Error, /Challenge has already been declined./
    end
  end
  context '#cancel!' do
    let(:challenge) { Fabricate(:challenge) }
    it 'can be canceled by challenger' do
      canceled_by = challenge.challengers.first
      challenge.cancel!(canceled_by)
      expect(challenge.updated_by).to eq canceled_by
      expect(challenge.state).to eq ChallengeState::CANCELED
    end
    it 'can be canceled by challenged' do
      canceled_by = challenge.challenged.first
      challenge.cancel!(canceled_by)
      expect(challenge.updated_by).to eq canceled_by
      expect(challenge.state).to eq ChallengeState::CANCELED
    end
    it 'requires canceled_by' do
      challenge.state = ChallengeState::CANCELED
      expect(challenge).to_not be_valid
    end
    it 'cannot be canceled_by by another player' do
      player = Fabricate(:user)
      expect do
        challenge.cancel!(player)
      end.to raise_error Mongoid::Errors::Validations, /Only #{challenge.challengers.map(&:user_name).and} or #{challenge.challenged.map(&:user_name).and} can cancel this challenge./
    end
    it 'cannot be canceled_by twice' do
      canceled_by = challenge.challengers.first
      challenge.cancel!(canceled_by)
      expect do
        challenge.cancel!(canceled_by)
      end.to raise_error SlackGamebot::Error, /Challenge has already been canceled./
    end
  end
  context '#lose!' do
    let(:challenge) { Fabricate(:challenge) }
    before do
      challenge.accept!(challenge.challenged.first)
    end
    it 'can be lost by the challenger' do
      expect do
        challenge.lose!(challenge.challengers.first)
      end.to change(Match, :count).by(1)
      game = Match.last
      expect(game.challenge).to eq challenge
      expect(game.winners).to eq challenge.challenged
      expect(game.losers).to eq challenge.challengers
      expect(game.winners.all? { |player| player.wins == 1 && player.losses == 0 }).to be true
      expect(game.losers.all? { |player| player.wins == 0 && player.losses == 1 }).to be true
    end
    it 'can be lost by the challenged' do
      expect do
        challenge.lose!(challenge.challenged.first)
      end.to change(Match, :count).by(1)
      game = Match.last
      expect(game.challenge).to eq challenge
      expect(game.winners).to eq challenge.challengers
      expect(game.losers).to eq challenge.challenged
      expect(game.winners.all? { |player| player.wins == 1 && player.losses == 0 }).to be true
      expect(game.losers.all? { |player| player.wins == 0 && player.losses == 1 }).to be true
    end
  end
  context '#draw!' do
    let(:challenge) { Fabricate(:challenge) }
    before do
      challenge.accept!(challenge.challenged.first)
    end
    it 'requires both sides to draw' do
      expect do
        challenge.draw!(challenge.challengers.first)
      end.to_not change(Match, :count)
      expect do
        challenge.draw!(challenge.challenged.first)
      end.to change(Match, :count).by(1)
      game = Match.last
      expect(game.tied?).to be true
      expect(game.challenge).to eq challenge
      expect(game.winners).to eq challenge.challengers
      expect(game.losers).to eq challenge.challenged
      expect(game.winners.all? { |player| player.wins == 0 && player.losses == 0 && player.ties == 1 }).to be true
      expect(game.losers.all? { |player| player.wins == 0 && player.losses == 0 && player.ties == 1 }).to be true
    end
  end
  context 'a new challenge' do
    let(:played_challenge) { Fabricate(:played_challenge) }
    let(:new_challenge) { Fabricate(:challenge, challengers: played_challenge.challengers, challenged: played_challenge.challenged) }
    it 'does not render the played challenge invalid' do
      expect(new_challenge).to be_valid
      expect(played_challenge).to be_valid
    end
  end
end
