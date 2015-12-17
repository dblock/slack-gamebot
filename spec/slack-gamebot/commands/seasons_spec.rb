require 'spec_helper'

describe SlackGamebot::Commands::Seasons, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::Server.new }
  context 'no seasons' do
    it 'seasons' do
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message "There're no seasons."
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
  end
  context 'current season' do
    before do
      2.times.map { Fabricate(:match) }
    end
    it 'returns past seasons and current season' do
      current_season = Season.new
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message current_season.to_s
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
      Season.new
    end
    it 'returns past seasons and current season' do
      expect(message: "#{SlackRubyBot.config.user} seasons").to respond_with_slack_message [current_season, season1].map(&:to_s).join("\n")
    end
  end
end
