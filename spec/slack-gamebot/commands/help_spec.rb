require 'spec_helper'

describe SlackGamebot::Commands::Help do
  let!(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  it 'help' do
    expect(message: "#{SlackRubyBot.config.user} help").to respond_with_slack_message(SlackGamebot::Commands::Help::HELP)
  end
end
