require 'spec_helper'

describe SlackGamebot::Commands::Hi do
  it 'says hi' do
    expect(message: 'gamebot hi').to respond_with_slack_message('Hi <@user>!')
  end
end
