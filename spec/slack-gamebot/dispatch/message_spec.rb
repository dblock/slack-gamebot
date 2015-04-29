require 'spec_helper'

describe SlackGamebot::Dispatch::Message do
  let(:app) { SlackGamebot::App.new }
  before do
    SlackGamebot.config.user = 'gamebot'
  end
  it 'gamebot' do
    expect(subject).to receive(:message).with('channel', SlackGamebot::ASCII)
    app.send(:message, text: 'gamebot', channel: 'channel', user: 'user')
  end
  it 'hi' do
    expect(subject).to receive(:message).with('channel', 'Hi <@user>!')
    app.send(:message, text: 'gamebot hi', channel: 'channel', user: 'user')
  end
  it 'invalid command' do
    expect(subject).to receive(:message).with('channel', "Sorry <@user>, I don't understand that command!")
    app.send(:message, text: 'gamebot foobar', channel: 'channel', user: 'user')
  end
  context 'register', vcr: { cassette_name: 'user_info' } do
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
end
