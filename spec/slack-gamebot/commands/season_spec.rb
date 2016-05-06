require 'spec_helper'

describe SlackGamebot::Commands::Season, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  shared_examples_for 'season' do
    context 'no seasons' do
      it 'seasons' do
        expect(message: "#{SlackRubyBot.config.user} season").to respond_with_slack_message "There're no seasons."
      end
    end
    context 'current season' do
      before do
        Fabricate(:match)
      end
      it 'returns current season' do
        current_season = Season.new(team: team)
        expect(message: "#{SlackRubyBot.config.user} season").to respond_with_slack_message current_season.to_s
      end
      context 'after reset' do
        before do
          ::Season.create!(team: team, created_by: User.first)
        end
        it 'returns current season' do
          expect(message: "#{SlackRubyBot.config.user} season").to respond_with_slack_message 'No matches have been recorded.'
        end
      end
    end
  end
  it_behaves_like 'season'
  context 'with another team' do
    let!(:team2) { Fabricate(:team) }
    let!(:match2) { Fabricate(:match, team: team2) }
    let!(:season2) { Fabricate(:season, team: team2) }
    it_behaves_like 'season'
  end
end
