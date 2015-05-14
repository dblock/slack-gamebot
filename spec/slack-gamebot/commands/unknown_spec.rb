require 'spec_helper'

describe SlackGamebot::Commands::Unknown, vcr: { cassette_name: 'user_info' } do
  it 'invalid command' do
    expect(message: 'gamebot foobar').to respond_with_slack_message("Sorry <@user>, I don't understand that command!")
  end
  it 'does not respond to sad face' do
    expect(SlackGamebot::Commands::Base).to_not receive(:send_message)
    SlackGamebot::App.new.send(:message, text: ':((')
  end
end
