require 'spec_helper'

describe SlackGamebot::Commands::Default do
  it 'gamebot' do
    expect(message: 'gamebot').to respond_with_slack_message(SlackGamebot::ASCII)
  end
  it 'Gamebot' do
    expect(message: 'Gamebot').to respond_with_slack_message(SlackGamebot::ASCII)
  end
end
