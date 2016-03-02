require 'spec_helper'

describe SlackGamebot::Commands::Team, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  context 'no users' do
    it 'team' do
      allow(User).to receive(:find_create_or_update_by_slack_id!)
      expect(message: "#{SlackRubyBot.config.user} team").to respond_with_slack_message "Team _#{team.name}_ (#{team.team_id})."
    end
  end
  context 'with a captain' do
    let!(:user) { Fabricate(:user, team: team, user_name: 'username', captain: true) }
    it 'team' do
      expect(message: "#{SlackRubyBot.config.user} team").to respond_with_slack_message "Team _#{team.name}_ (#{team.team_id}), captain username."
    end
  end
  context 'with two captains' do
    before do
      2.times.map { Fabricate(:user, team: team, captain: true) }
    end
    it 'team' do
      expect(message: "#{SlackRubyBot.config.user} team").to respond_with_slack_message "Team _#{team.name}_ (#{team.team_id}), captains #{team.captains.map(&:user_name).and}."
    end
  end
end
