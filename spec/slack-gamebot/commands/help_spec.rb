require 'spec_helper'

describe SlackGamebot::Commands::Help do
  let(:app) { SlackGamebot::App.new }
  it 'help' do
    expect(message: "#{SlackRubyBot.config.user} help").to respond_with_slack_message('See https://github.com/dblock/slack-gamebot, please.')
  end
end
