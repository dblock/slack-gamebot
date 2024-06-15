require 'spec_helper'

describe SlackGamebot::Commands::ChallengeQuestion, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, user_name: 'username') }
  let(:opponent) { Fabricate(:user) }

  it 'displays elo at stake for a singles challenge' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge? <@#{opponent.user_id}>", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.slack_mention} challenging #{opponent.slack_mention} to a match is worth 48 elo."
      )
    end.not_to change(Challenge, :count)
  end

  it 'displays elo at stake for a doubles challenge' do
    opponent2 = Fabricate(:user, team: team)
    teammate = Fabricate(:user, team: team)
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge? #{opponent.slack_mention} #{opponent2.user_name} with #{teammate.user_name}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.slack_mention} and #{teammate.slack_mention} challenging #{opponent.slack_mention} and #{opponent2.slack_mention} to a match is worth 48 elo."
      )
    end.not_to change(Challenge, :count)
  end

  context 'with unbalanced option enabled' do
    before do
      team.update_attributes!(unbalanced: true)
    end

    it 'displays elo at stake with different number of opponents' do
      opponent1 = Fabricate(:user)
      opponent2 = Fabricate(:user)
      expect do
        expect(message: "#{SlackRubyBot.config.user} challenge? #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
          "#{user.slack_mention} challenging #{opponent1.slack_mention} and #{opponent2.slack_mention} to a match is worth 24 and 48 elo."
        )
      end.not_to change(Challenge, :count)
    end
  end

  context 'subscription expiration' do
    before do
      team.update_attributes!(created_at: 3.weeks.ago)
    end

    it 'prevents new challenge questions' do
      expect(message: "#{SlackRubyBot.config.user} challenge? <@#{opponent.user_id}>", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "Your trial subscription has expired. Subscribe your team for $29.99 a year at https://www.playplay.io/subscribe?team_id=#{team.team_id}&game=#{team.game.name}."
      )
    end
  end
end
