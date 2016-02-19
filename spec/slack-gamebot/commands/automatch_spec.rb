require 'spec_helper'

describe SlackGamebot::Commands::Automatch, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:user1) { Fabricate(:user, user_name: 'username1', elo: 1) }
  let(:user2) { Fabricate(:user, user_name: 'username2', elo: 2) }
  let(:user3) { Fabricate(:user, user_name: 'username3', elo: 3) }
  let(:user4) { Fabricate(:user, user_name: 'username4', elo: 4) }
  let(:opponent) { Fabricate(:user) }

  it 'sets automatch flag to true when user turns it on' do
    expect(message: "#{SlackRubyBot.config.user} automatch on", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
      'Automatch is on for username (1 users ready to play!)'
    )

    user1.reload
    expect(user1.automatch).to be(true)
  end

  it 'sets automatch flag to false when user turns it off' do
    expect(message: "#{SlackRubyBot.config.user} automatch off", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
      'Automatch is off for username (0 users ready to play!)'
    )

    user1.reload
    expect(user1.automatch).to be(false)
  end

  it 'toggles automatch flag from off to on when there is no argument' do
    user1.automatch = false
    user1.save!

    expect(message: "#{SlackRubyBot.config.user} automatch", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
      'Automatch is on for username (1 users ready to play!)'
    )

    user1.reload
    expect(user1.automatch).to be(true)
  end

  it 'toggles automatch flag from on to off when there is no argument' do
    user1.automatch = true
    user1.save!

    expect(message: "#{SlackRubyBot.config.user} automatch", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
      'Automatch is off for username (0 users ready to play!)'
    )

    user1.reload
    expect(user1.automatch).to be(false)
  end

  it 'creates a doubles match when four users have automatch on' do
    [user1, user2, user3].each do |user|
      user.automatch = true
      user.save!
    end

    expect do
      expect(message: "#{SlackRubyBot.config.user} automatch", user: user4.user_id, channel: 'pongbot').to respond_with_slack_message(
        'Automatch: username1 and username vs username2 and username3!'
      )
    end.to change(Challenge, :count).by(1)
  end

  it 'matches top and bottom elo vs middle two elo' do
    [user1, user2, user3].each do |user|
      user.automatch = true
      user.save!
    end

    expect(message: "#{SlackRubyBot.config.user} automatch", user: user4.user_id, channel: 'pongbot').to respond_with_slack_message(
      'Automatch: username1 and username vs username2 and username3!'
    )

    challenge = Challenge.last
    expect(challenge.challengers.length).to eq(2)
    expect(challenge.challengers.include?(user1)).to eq(true)
    expect(challenge.challengers.include?(user4)).to eq(true)
    expect(challenge.challenged.length).to eq(2)
    expect(challenge.challenged.include?(user2)).to eq(true)
    expect(challenge.challenged.include?(user3)).to eq(true)
  end
end
