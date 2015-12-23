require 'spec_helper'

describe SlackGamebot::Commands::Seasons, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  context 'no seasons' do
    it 'seasons' do
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message "There're no seasons."
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:match2) { Fabricate(:match, team: team2) }
      let!(:season2) { Fabricate(:season, team: team2) }
      it 'displays no seasons for team 1' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message "There're no seasons."
      end
    end
  end
  context 'one season' do
    before do
      2.times.map { Fabricate(:match) }
      challenge = Fabricate(:challenge, challengers: [User.asc(:_id).first], challenged: [User.asc(:_id).last])
      Fabricate(:match, challenge: challenge)
    end
    let!(:season) { Fabricate(:season) }
    it 'seasons' do
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message season.to_s
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:match2) { Fabricate(:match, team: team2) }
      let!(:season2) { Fabricate(:season, team: team2) }
      it 'displays seasons for team 1' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message season.to_s
      end
    end
  end
  context 'two seasons' do
    let!(:seasons) do
      2.times.map do |n|
        User.all.destroy
        (n + 1).times.map { Fabricate(:match) }
        challenge = Fabricate(:challenge, challengers: [User.asc(:_id).first], challenged: [User.asc(:_id).last])
        Fabricate(:match, challenge: challenge)
        Fabricate(:season)
      end
    end
    it 'returns past seasons and current season' do
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message seasons.reverse.map(&:to_s).join("\n")
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:match2) { Fabricate(:match, team: team2) }
      let!(:season2) { Fabricate(:season, team: team2) }
      it 'displays seasons and current season for team 1' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message seasons.reverse.map(&:to_s).join("\n")
      end
    end
  end
  context 'current season' do
    before do
      2.times.map { Fabricate(:match) }
    end
    it 'returns past seasons and current season' do
      current_season = Season.new(team: team)
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message current_season.to_s
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:match2) { Fabricate(:match, team: team2) }
      let!(:season2) { Fabricate(:season, team: team2) }
      it 'returns past seasons and current season' do
        current_season = Season.new(team: team)
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message current_season.to_s
      end
    end
  end
  context 'current and past season' do
    let!(:season1) do
      2.times.map { Fabricate(:match) }
      challenge = Fabricate(:challenge, challengers: [User.asc(:_id).first], challenged: [User.asc(:_id).last])
      Fabricate(:match, challenge: challenge)
      Fabricate(:season)
    end
    let!(:current_season) do
      2.times.map { Fabricate(:match) }
      Season.new(team: team)
    end
    it 'returns past seasons and current season' do
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message [current_season, season1].map(&:to_s).join("\n")
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:match2) { Fabricate(:match, team: team2) }
      let!(:season2) { Fabricate(:season, team: team2) }
      it 'returns past seasons and current season' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message [current_season, season1].map(&:to_s).join("\n")
      end
    end
  end
end
