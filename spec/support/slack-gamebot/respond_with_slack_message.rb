require 'rspec/expectations'

RSpec::Matchers.define :respond_with_slack_message do |expected|
  match do |actual|
    channel = 'channel'
    user = 'user'
    message = ''
    if actual.is_a?(Hash)
      channel = actual[:channel] if actual.key?(:channel)
      user = actual[:user] if actual.key?(:user)
      message = actual[:message]
    else
      message = actual
    end
    app = SlackGamebot::App.new
    SlackGamebot.config.user = 'gamebot'
    allow(Giphy).to receive(:random)
    expect(SlackGamebot::Commands::Base).to receive(:send_message).with(channel, expected)
    app.send(:message, text: message, channel: channel, user: user)
    true
  end
end
