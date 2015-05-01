require 'spec_helper'

describe Challenge do
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
        Challenge.create_from_teammates_and_opponents!(@challenger, [])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(1\) and opponents \(0\) must match./
    end
    it 'requires another opponent' do
      expect do
        Challenge.create_from_teammates_and_opponents!(@challenger, [@challenger.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /#{@challenger.user_name} cannot play against themselves./
    end
    it 'uniques opponents mentioned multiple times' do
      teammate = Fabricate(:user)
      opponent = Fabricate(:user)
      expect do
        Challenge.create_from_teammates_and_opponents!(@challenger, [opponent.slack_mention, opponent.slack_mention, 'with', teammate.slack_mention])
      end.to raise_error Mongoid::Errors::Validations, /Number of teammates \(2\) and opponents \(1\) must match./
    end
    context 'with another singles proposed challenge' do
      before do
        @challenge = Fabricate(:challenge)
      end
      it 'cannot create a duplicate challenge for the challenger' do
        existing_challenger = @challenge.challengers.first
        expect do
          Challenge.create_from_teammates_and_opponents!(@challenger, [existing_challenger.slack_mention])
        end.to raise_error Mongoid::Errors::Validations, /#{existing_challenger.user_name} can't play./
      end
      it 'cannot create a duplicate challenge for the challenge' do
        existing_challenger = @challenge.challenged.first
        expect do
          Challenge.create_from_teammates_and_opponents!(@challenger, [existing_challenger.slack_mention])
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
          Challenge.create_from_teammates_and_opponents!(@challenger, [existing_challenger.slack_mention])
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
      expect(@challenge.accepted_by).to eq accepted_by
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
    it 'can be declineed' do
      declined_by = @challenge.challenged.first
      @challenge.decline!(declined_by)
      expect(@challenge.declined_by).to eq declined_by
      expect(@challenge.state).to eq ChallengeState::DECLINED
    end
    it 'requires declined_by' do
      @challenge.state = ChallengeState::DECLINED
      expect(@challenge).to_not be_valid
    end
    it 'cannot be declineed by another player' do
      expect do
        @challenge.decline!(@challenge.challengers.first)
      end.to raise_error Mongoid::Errors::Validations, /Only #{@challenge.challenged.map(&:user_name).join(' ')} can decline this challenge./
    end
    it 'cannot be declineed twice' do
      declined_by = @challenge.challenged.first
      @challenge.decline!(declined_by)
      expect do
        @challenge.decline!(declined_by)
      end.to raise_error RuntimeError, /Challenge has already been declined./
    end
  end
end
