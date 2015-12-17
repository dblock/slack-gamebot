require 'spec_helper'

describe SlackRubyBot::Commands::Hi do
  let(:app) { SlackGamebot::Server.new }
  it 'says hi' do
    expect(message: "#{SlackRubyBot.config.user} hi").to respond_with_slack_message('Hi <@user>!')
  end
end
