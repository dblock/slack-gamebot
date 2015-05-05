require 'spec_helper'

describe SlackGamebot::Commands::Help do
  it 'help' do
    expect(message: 'gamebot help').to respond_with_slack_message('See https://github.com/dblock/slack-gamebot, please.')
  end
end
