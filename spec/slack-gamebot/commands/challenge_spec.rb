require 'spec_helper'

describe SlackGamebot::Commands::Challenge, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, user_name: 'username') }
  let(:opponent) { Fabricate(:user) }
  it 'creates a singles challenge by user id' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge <@#{opponent.user_id}>", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
    challenge = Challenge.last
    expect(challenge.channel).to eq 'pongbot'
    expect(challenge.created_by).to eq user
    expect(challenge.challengers).to eq [user]
    expect(challenge.challenged).to eq [opponent]
  end
  it 'creates a singles challenge by user name' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent.slack_mention}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end
  it 'creates a doubles challenge by user name' do
    opponent2 = Fabricate(:user, team:)
    teammate = Fabricate(:user, team:)
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent.slack_mention} #{opponent2.user_name} with #{teammate.user_name}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.slack_mention} and #{teammate.slack_mention} challenged #{opponent.slack_mention} and #{opponent2.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
    challenge = Challenge.last
    expect(challenge.channel).to eq 'pongbot'
    expect(challenge.created_by).to eq user
    expect(challenge.challengers).to eq [teammate, user]
    expect(challenge.challenged).to eq [opponent2, opponent]
  end
  it 'creates a singles challenge by user name case-insensitive' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent.user_name.capitalize}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "#{user.slack_mention} challenged #{opponent.slack_mention} to a match!"
      )
    end.to change(Challenge, :count).by(1)
  end
  it 'requires an opponent' do
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        'Number of teammates (1) and opponents (0) must match.'
      )
    end.to_not change(Challenge, :count)
  end
  it 'requires the same number of opponents' do
    opponent1 = Fabricate(:user)
    opponent2 = Fabricate(:user)
    expect do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        'Number of teammates (1) and opponents (2) must match.'
      )
    end.to_not change(Challenge, :count)
  end
  context 'with unbalanced option enabled' do
    before do
      team.update_attributes!(unbalanced: true)
    end
    it 'allows different number of opponents' do
      opponent1 = Fabricate(:user)
      opponent2 = Fabricate(:user)
      expect do
        expect(message: "#{SlackRubyBot.config.user} challenge #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
          "#{user.slack_mention} challenged #{opponent1.slack_mention} and #{opponent2.slack_mention} to a match!"
        )
      end.to change(Challenge, :count).by(1)
      challenge = Challenge.last
      expect(challenge.challengers).to eq [user]
      expect(challenge.challenged).to eq [opponent1, opponent2]
    end
  end
  it 'does not butcher names with special characters' do
    allow(client.web_client).to receive(:users_info)
    expect(message: "#{SlackRubyBot.config.user} challenge Jung-hwa", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
      "I don't know who Jung-hwa is! Ask them to _register_."
    )
  end
  context 'requires the opponent to be registered' do
    before do
      opponent.unregister!
    end
    it 'by slack id' do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent.slack_mention}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "I don't know who #{opponent.slack_mention} is! Ask them to _register_."
      )
    end
    it 'requires the opponent to be registered by name' do
      expect(message: "#{SlackRubyBot.config.user} challenge #{opponent.user_name}", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "I don't know who #{opponent.user_name} is! Ask them to _register_."
      )
    end
  end
  context 'subscription expiration' do
    before do
      team.update_attributes!(created_at: 3.weeks.ago)
    end
    it 'prevents new challenges' do
      expect(message: "#{SlackRubyBot.config.user} challenge <@#{opponent.user_id}>", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
        "Your trial subscription has expired. Subscribe your team for $29.99 a year at https://www.playplay.io/subscribe?team_id=#{team.team_id}&game=#{team.game.name}."
      )
    end
  end
  User::EVERYONE.each do |username|
    it "challenges #{username}" do
      expect do
        expect(message: "#{SlackRubyBot.config.user} challenge <!#{username}>", user: user.user_id, channel: 'pongbot').to respond_with_slack_message(
          "#{user.slack_mention} challenged anyone to a match!"
        )
      end.to change(Challenge, :count).by(1)
      challenge = Challenge.last
      expect(challenge.channel).to eq 'pongbot'
      expect(challenge.created_by).to eq user
      expect(challenge.challengers).to eq [user]
      expect(challenge.challenged).to eq team.users.everyone
    end
  end
end
