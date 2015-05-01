require 'spec_helper'

describe SlackGamebot::Dispatch::Message do
  let(:app) { SlackGamebot::App.new }
  before do
    SlackGamebot.config.user = 'gamebot'
    allow(Giphy).to receive(:random)
  end
  it 'gamebot' do
    expect(subject).to receive(:message).with('channel', SlackGamebot::ASCII)
    app.send(:message, text: 'gamebot', channel: 'channel', user: 'user')
  end
  it 'Gamebot' do
    expect(subject).to receive(:message).with('channel', SlackGamebot::ASCII)
    app.send(:message, text: 'Gamebot', channel: 'channel', user: 'user')
  end
  it 'hi' do
    expect(subject).to receive(:message).with('channel', 'Hi <@user>!')
    app.send(:message, text: 'gamebot hi', channel: 'channel', user: 'user')
  end
  it 'help' do
    expect(subject).to receive(:message).with('channel', 'See https://github.com/dblock/slack-gamebot, please.')
    app.send(:message, text: 'gamebot help', channel: 'channel', user: 'user')
  end
  it 'invalid command' do
    expect(subject).to receive(:message).with('channel', "Sorry <@user>, I don't understand that command!")
    app.send(:message, text: 'gamebot foobar', channel: 'channel', user: 'user')
  end
  context 'as a user', vcr: { cassette_name: 'user_info' } do
    context 'register' do
      it 'registers a new user' do
        expect(subject).to receive(:message).with('channel', "Welcome <@user>! You're ready to play.")
        app.send(:message, text: 'gamebot register', channel: 'channel', user: 'user')
      end
      it 'renames an existing user' do
        Fabricate(:user, user_id: 'user')
        expect(subject).to receive(:message).with('channel', "Welcome back <@user>, I've updated your registration.")
        app.send(:message, text: 'gamebot register', channel: 'channel', user: 'user')
      end
      it 'already registered' do
        Fabricate(:user, user_id: 'user', user_name: 'username')
        expect(subject).to receive(:message).with('channel', "Welcome back <@user>, you're already registered.")
        app.send(:message, text: 'gamebot register', channel: 'channel', user: 'user')
      end
    end
    context 'with a user record' do
      context 'challenge' do
        it 'creates a singles challenge' do
          user = Fabricate(:user, user_name: 'username')
          opponent = Fabricate(:user)
          expect do
            expect(subject).to receive(:message).with('channel', "#{user.user_name} challenged #{opponent.user_name} to a match!")
            app.send(:message, text: "gamebot challenge <@#{opponent.user_id}>", channel: 'channel', user: user.user_id)
          end.to change(Challenge, :count).by(1)
          challenge = Challenge.last
          expect(challenge.created_by).to eq user
          expect(challenge.challengers).to eq [user]
          expect(challenge.challenged).to eq [opponent]
        end
        it 'requires an opponent' do
          expect do
            expect do
              app.send(:message, text: 'gamebot challenge', channel: 'channel', user: 'user')
            end.to raise_error(ArgumentError, 'Number of teammates (1) and opponents (0) must match.')
          end.to_not change(Challenge, :count)
        end
      end
    end
    context 'with a challenged' do
      before do
        @challenged = Fabricate(:user, user_name: 'username')
        @challenge = Fabricate(:challenge, challenged: [@challenged])
      end
      it 'accept' do
        expect(subject).to receive(:message).with('channel', "#{@challenge.challenged.map(&:user_name).join(' and ')} accepted #{@challenge.challengers.map(&:user_name).join(' and ')} challenge.")
        app.send(:message, text: 'gamebot accept', channel: 'channel', user: @challenged.user_id)
        expect(@challenge.reload.state).to eq ChallengeState::ACCEPTED
      end
      it 'decline' do
        expect(subject).to receive(:message).with('channel', "#{@challenge.challenged.map(&:user_name).join(' and ')} declined #{@challenge.challengers.map(&:user_name).join(' and ')} challenge.")
        app.send(:message, text: 'gamebot decline', channel: 'channel', user: @challenged.user_id)
        expect(@challenge.reload.state).to eq ChallengeState::DECLINED
      end
    end
    context 'with a challenger' do
      before do
        @challenged = Fabricate(:user, user_name: 'username')
        @challenge = Fabricate(:challenge, challengers: [@challenged])
      end
      it 'cancel' do
        expect(subject).to receive(:message).with('channel', "#{@challenge.challengers.map(&:user_name).join(' and ')} canceled a challenge against #{@challenge.challenged.map(&:user_name).join(' and ')}.")
        app.send(:message, text: 'gamebot cancel', channel: 'channel', user: @challenged.user_id)
        expect(@challenge.reload.state).to eq ChallengeState::CANCELED
      end
    end
    context 'with an accepted challenge' do
      before do
        @challenged = Fabricate(:user, user_name: 'username')
        @challenge = Fabricate(:challenge, challenged: [@challenged])
        @challenge.accept!(@challenged)
      end
      it 'lose' do
        expect(subject).to receive(:message).with('channel', "Match has been recorded! #{@challenge.challengers.map(&:user_name).join(' and ')} defeated #{@challenge.challenged.map(&:user_name).join(' and ')}.")
        app.send(:message, text: 'gamebot lost', channel: 'channel', user: @challenged.user_id)
        @challenge.reload
        expect(@challenge.state).to eq ChallengeState::PLAYED
        expect(@challenge.match.winners).to eq @challenge.challengers
        expect(@challenge.match.losers).to eq @challenge.challenged
      end
    end
  end
  context 'leaderboard' do
    before do
      @user_elo_42 = Fabricate(:user, elo: 42, wins: 3, losses: 2)
      @user_elo_48 = Fabricate(:user, elo: 48, wins: 2, losses: 3)
    end
    it 'displays leaderboard sorted by elo' do
      expect(subject).to receive(:message).with('channel', "1. #{@user_elo_48}\n2. #{@user_elo_42}")
      app.send(:message, text: 'gamebot leaderboard', channel: 'channel')
    end
    it 'limits to max' do
      expect(subject).to receive(:message).with('channel', "1. #{@user_elo_48}")
      app.send(:message, text: 'gamebot leaderboard 1', channel: 'channel')
    end
    it 'supports infinity' do
      user_elo_43 = Fabricate(:user, elo: 43, wins: 2, losses: 3)
      user_elo_44 = Fabricate(:user, elo: 44, wins: 2, losses: 3)
      expect(subject).to receive(:message).with('channel', "1. #{@user_elo_48}\n2. #{user_elo_44}\n3. #{user_elo_43}\n4. #{@user_elo_42}")
      app.send(:message, text: 'gamebot leaderboard infinity', channel: 'channel')
    end
  end
end
