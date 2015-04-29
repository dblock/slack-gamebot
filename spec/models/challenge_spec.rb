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
end
