require 'spec_helper'

describe SlackGamebot::Commands::Seasons, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'team' do
    let!(:team) { Fabricate(:team) }
    it 'is a premium feature' do
      expect(message: "#{SlackRubyBot.config.user} seasons", user: 'user').to respond_with_slack_message(
        "This is a premium feature. Upgrade your team to premium for $29.99 a year at https://www.playplay.io/upgrade?team_id=#{team.team_id}&game=#{team.game.name}."
      )
    end
  end
  shared_examples_for 'seasons' do
    context 'no seasons' do
      it 'seasons' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message "There're no seasons."
      end
    end
    context 'one season' do
      before do
        2.times.map { Fabricate(:match, team: team) }
        challenge = Fabricate(:challenge, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
        Fabricate(:match, challenge: challenge)
      end
      let!(:season) { Fabricate(:season, team: team) }
      it 'seasons' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message season.to_s
      end
    end
    context 'two seasons' do
      let!(:seasons) do
        2.times.map do |n|
          team.users.all.destroy
          (n + 1).times.map { Fabricate(:match, team: team) }
          challenge = Fabricate(:challenge, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
          Fabricate(:match, challenge: challenge)
          Fabricate(:season)
        end
      end
      it 'returns past seasons and current season' do
        expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message seasons.reverse.map(&:to_s).join("\n")
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
    end
    context 'current and past season' do
      let!(:season1) do
        2.times.map { Fabricate(:match) }
        challenge = Fabricate(:challenge, challengers: [team.users.asc(:_id).first], challenged: [team.users.asc(:_id).last])
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
    end
  end
  context 'premium team' do
    let!(:team) { Fabricate(:team, premium: true) }
    it_behaves_like 'seasons'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:match2) { Fabricate(:match, team: team2) }
      let!(:season2) { Fabricate(:season, team: team2) }
      it_behaves_like 'seasons'
    end
  end
end
