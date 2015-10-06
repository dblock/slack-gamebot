require 'spec_helper'

describe SlackGamebot::Commands::Season, vcr: { cassette_name: 'user_info' } do
  let(:app) { SlackGamebot::App.new }
  context 'no seasons' do
    it 'seasons' do
      expect(message: "#{SlackRubyBot.config.user} season").to respond_with_slack_message "There're no seasons."
    end
  end
  context 'current season' do
    before do
      2.times.map { Fabricate(:match) }
    end
    it 'returns current season' do
      current_season = Season.new
      expect(message: "#{SlackRubyBot.config.user} season").to respond_with_slack_message current_season.to_s
    end
    context 'after reset' do
      before do
        ::Season.create!(created_by: User.first)
      end
      it 'returns current season' do
        expect(message: "#{SlackRubyBot.config.user} season").to respond_with_slack_message 'No matches have been recorded.'
      end
    end
  end
end
