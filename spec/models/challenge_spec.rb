require 'spec_helper'

describe Challenge do
  context 'find_by_user' do
    before do
      @challenge = Fabricate(:challenge)
    end
    it 'finds a challenge by challenger' do
      @challenge.challengers.each do |challenger|
        expect(Challenge.find_by_user(@challenge.channel, challenger)).to eq @challenge
      end
    end
    it 'finds a challenge by challenged' do
      @challenge.challenged.each do |challenger|
        expect(Challenge.find_by_user(@challenge.channel, challenger)).to eq @challenge
      end
    end
    it 'does not find a challenge on another channel' do
      expect(Challenge.find_by_user('another', @challenge.challengers.first)).to be nil
    end
  end
  context '#split_teammates_and_opponents', vcr: { cassette_name: 'user_info' } do
    before do
      @challenger = Fabricate(:user)
    end
    it 'splits a single challenge' do
      opponent = Fabricate(:user, user_name: 'username')
      challengers, opponents = Challenge.split_teammates_and_opponents(@challenger, ['username'])
      expect(challengers).to eq([@challenger])
      expect(opponents).to eq([opponent])
    end
    it 'splits a double challenge' do
      teammate = Fabricate(:user)
      opponent1 = Fabricate(:user, user_name: 'username')
      opponent2 = Fabricate(:user)
      challengers, opponents = Challenge.split_teammates_and_opponents(@challenger, ['username', opponent2.slack_mention, 'with', teammate.slack_mention])
      expect(challengers).to eq([@challenger, teammate])
      expect(opponents).to eq([opponent1, opponent2])
    end
    it 'requires known opponents' do
      expect do
        Challenge.split_teammates_and_opponents(@challenger, ['username'])
      end.to raise_error ArgumentError, "I don't know who username is! Ask them to _testbot register_."
    end
  end
  context '#create_from_teammates_and_opponents!' do
    before do
      @challenger = Fabricate(:user)
    end
    it 'requires an opponent' do
      expect do
        Challenge.create_from_teammates_and_opponents!('channel', @challenger, [])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(1\) and opponents \(0\) must match./
    end
    it 'requires another opponent' do
      expect do
        Challenge.create_from_teammates_and_opponents!('channel', @challenger, [@challenger.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /#{@challenger.user_name} cannot play against themselves./
    end
    it 'uniques opponents mentioned multiple times' do
      teammate = Fabricate(:user)
      opponent = Fabricate(:user)
      expect do
        Challenge.create_from_teammates_and_opponents!('channel', @challenger, [opponent.slack_mention, opponent.slack_mention, 'with', teammate.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(2\) and opponents \(1\) must match./
    end
    context 'with another singles proposed challenge' do
      before do
        @challenge = Fabricate(:challenge)
      end
      it 'cannot create a duplicate challenge for the challenger' do
        existing_challenger = @challenge.challengers.first
        expect do
          Challenge.create_from_teammates_and_opponents!(@challenge.channel, @challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
      it 'cannot create a duplicate challenge for the challenge' do
        existing_challenger = @challenge.challenged.first
        expect do
          Challenge.create_from_teammates_and_opponents!(@challenge.channel, @challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
    end
    context 'with another doubles proposed challenge' do
      before do
        @challenge = Fabricate(:challenge, challengers: [Fabricate(:user), Fabricate(:user)], challenged: [Fabricate(:user), Fabricate(:user)])
      end
      it 'cannot create a duplicate challenge for the challenger' do
        existing_challenger = @challenge.challengers.last
        expect do
          Challenge.create_from_teammates_and_opponents!(@challenge.channel, @challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
    end
  end
  context '#accept!' do
    before do
      @challenge = Fabricate(:challenge)
    end
    it 'can be accepted' do
      accepted_by = @challenge.challenged.first
      @challenge.accept!(accepted_by)
      expect(@challenge.updated_by).to eq accepted_by
      expect(@challenge.state).to eq ChallengeState::ACCEPTED
    end
    it 'requires accepted_by' do
      @challenge.state = ChallengeState::ACCEPTED
      expect(@challenge).to_not be_valid
    end
    it 'cannot be accepted by another player' do
      expect do
        @challenge.accept!(@challenge.challengers.first)
      end.to raise_error Mongoid::Errors::Validations, /Only #{@challenge.challenged.map(&:user_name).join(' ')} can accept this challenge./
    end
    it 'cannot be accepted twice' do
      accepted_by = @challenge.challenged.first
      @challenge.accept!(accepted_by)
      expect do
        @challenge.accept!(accepted_by)
      end.to raise_error RuntimeError, /Challenge has already been accepted./
    end
  end
  context '#decline!' do
    before do
      @challenge = Fabricate(:challenge)
    end
    it 'can be declined' do
      declined_by = @challenge.challenged.first
      @challenge.decline!(declined_by)
      expect(@challenge.updated_by).to eq declined_by
      expect(@challenge.state).to eq ChallengeState::DECLINED
    end
    it 'requires declined_by' do
      @challenge.state = ChallengeState::DECLINED
      expect(@challenge).to_not be_valid
    end
    it 'cannot be declined by another player' do
      expect do
        @challenge.decline!(@challenge.challengers.first)
      end.to raise_error Mongoid::Errors::Validations, /Only #{@challenge.challenged.map(&:user_name).join(' ')} can decline this challenge./
    end
    it 'cannot be declined twice' do
      declined_by = @challenge.challenged.first
      @challenge.decline!(declined_by)
      expect do
        @challenge.decline!(declined_by)
      end.to raise_error RuntimeError, /Challenge has already been declined./
    end
  end
  context '#cancel!' do
    before do
      @challenge = Fabricate(:challenge)
    end
    it 'can be canceled by challenger' do
      canceled_by = @challenge.challengers.first
      @challenge.cancel!(canceled_by)
      expect(@challenge.updated_by).to eq canceled_by
      expect(@challenge.state).to eq ChallengeState::CANCELED
    end
    it 'can be canceled by challenged' do
      canceled_by = @challenge.challenged.first
      @challenge.cancel!(canceled_by)
      expect(@challenge.updated_by).to eq canceled_by
      expect(@challenge.state).to eq ChallengeState::CANCELED
    end
    it 'requires canceled_by' do
      @challenge.state = ChallengeState::CANCELED
      expect(@challenge).to_not be_valid
    end
    it 'cannot be canceled_by by another player' do
      player = Fabricate(:user)
      expect do
        @challenge.cancel!(player)
      end.to raise_error Mongoid::Errors::Validations, /Only #{@challenge.challengers.map(&:user_name).join(' and ')} or #{@challenge.challenged.map(&:user_name).join(' ')} can cancel this challenge./
    end
    it 'cannot be canceled_by twice' do
      canceled_by = @challenge.challengers.first
      @challenge.cancel!(canceled_by)
      expect do
        @challenge.cancel!(canceled_by)
      end.to raise_error RuntimeError, /Challenge has already been canceled./
    end
  end
  context '#lose!' do
    before do
      @challenge = Fabricate(:challenge)
      @challenge.accept!(@challenge.challenged.first)
    end
    it 'can be lost by the challenger' do
      expect do
        @challenge.lose!(@challenge.challengers.first)
      end.to change(Match, :count).by(1)
      game = Match.last
      expect(game.challenge).to eq @challenge
      expect(game.winners).to eq @challenge.challenged
      expect(game.losers).to eq @challenge.challengers
      expect(game.winners.all? { |player| player.wins == 1 && player.losses == 0 }).to be true
      expect(game.losers.all? { |player| player.wins == 0 && player.losses == 1 }).to be true
    end
    it 'can be lost by the challenged' do
      expect do
        @challenge.lose!(@challenge.challenged.first)
      end.to change(Match, :count).by(1)
      game = Match.last
      expect(game.challenge).to eq @challenge
      expect(game.winners).to eq @challenge.challengers
      expect(game.losers).to eq @challenge.challenged
      expect(game.winners.all? { |player| player.wins == 1 && player.losses == 0 }).to be true
      expect(game.losers.all? { |player| player.wins == 0 && player.losses == 1 }).to be true
    end
  end
end
