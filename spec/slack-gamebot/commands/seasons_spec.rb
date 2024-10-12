require 'spec_helper'

describe SlackGamebot::Commands::Seasons, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }

  shared_examples_for 'seasons' do
    context 'no seasons' do
      it 'seasons' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message "There're no seasons."
      end
    end

    context 'one season' do
      before do
        Array.new(2) { Fabricate(:match, team:) }
        challenge = Fabricate(:challenge, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
        Fabricate(:match, challenge:)
      end

      let!(:season) { Fabricate(:season, team:) }

      it 'seasons' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message season.to_s
      end
    end

    context 'two seasons' do
      let!(:seasons) do
        Array.new(2) do |n|
          team.users.all.destroy
          Array.new((n + 1)) { Fabricate(:match, team:) }
          challenge = Fabricate(:challenge, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
          Fabricate(:match, challenge:)
          Fabricate(:season)
        end
      end

      it 'returns past seasons and current season' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message seasons.reverse.map(&:to_s).join("\n")
      end
    end

    context 'current season' do
      before do
        Array.new(2) { Fabricate(:match) }
      end

      it 'returns past seasons and current season' do
        current_season = Season.new(team:)
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message current_season.to_s
      end
    end

    context 'current and past season' do
      let!(:season1) do
        Array.new(2) { Fabricate(:match) }
        challenge = Fabricate(:challenge, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
        Fabricate(:match, challenge:)
        Fabricate(:season)
      end
      let!(:current_season) do
        Array.new(2) { Fabricate(:match) }
        Season.new(team:)
      end

      it 'returns past seasons and current season' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message [current_season, season1].map(&:to_s).join("\n")
      end
    end
  end

  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    it_behaves_like 'seasons'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:match2) { Fabricate(:match, team: team2) }
      let!(:season2) { Fabricate(:season, team: team2) }

      it_behaves_like 'seasons'
    end
  end
end
