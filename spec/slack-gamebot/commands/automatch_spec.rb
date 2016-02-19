require 'spec_helper'

describe SlackGamebot::Commands::Automatch, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:user1) { Fabricate(:user, user_name: 'username1', elo: 1) }
  let(:user2) { Fabricate(:user, user_name: 'username2', elo: 2) }
  let(:user3) { Fabricate(:user, user_name: 'username3', elo: 3) }
  let(:user4) { Fabricate(:user, user_name: 'username4', elo: 4) }
  let(:opponent) { Fabricate(:user) }

  it 'sets automatch time to 5 minutes in the future when user turns it on' do
    Timecop.freeze(Time.now.beginning_of_minute) do
      expect(message: "#{SlackRubyBot.config.user} automatch on", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
        'Automatch is on for username (1 users ready to play!)'
      )

      user1.reload
      expect(user1.automatch_time).to eq(5.minutes.from_now)
    end
  end

  it 'sets automatch flag to false when user turns it off' do
    expect(message: "#{SlackRubyBot.config.user} automatch off", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
      'Automatch is off for username (0 users ready to play!)'
    )

    user1.reload
    expect(user1.automatch_time).to be(nil)
  end

  it 'creates a doubles match when four users have automatch on' do
    [user1, user2, user3].each do |user|
      user.automatch_time = 5.minutes.from_now
      user.save!
    end

    expect do
      expect(message: "#{SlackRubyBot.config.user} automatch on", user: user4.user_id, channel: 'pongbot').to respond_with_slack_message(
        'Automatch: username1 and username vs username2 and username3!'
      )
    end.to change(Challenge, :count).by(1)
  end

  it 'matches top and bottom elo vs middle two elo' do
    [user1, user2, user3].each do |user|
      user.automatch_time = 5.minutes.from_now
      user.save!
    end

    expect(message: "#{SlackRubyBot.config.user} automatch on", user: user4.user_id, channel: 'pongbot').to respond_with_slack_message(
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

  it 'times out after 5 minutes' do
    [user1, user2, user3].each do |user|
      user.automatch_time = 5.minutes.from_now
      user.save!
    end

    expect(message: "#{SlackRubyBot.config.user} automatch on", user: user4.user_id, channel: 'pongbot').to respond_with_slack_message(
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

  context 'until' do
    it 'sets automatch time for relative time' do
      Timecop.freeze(Time.now.beginning_of_minute) do
        expect(message: "#{SlackRubyBot.config.user} automatch until 30 minutes from now", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
          'Automatch is on for username (1 users ready to play!)'
        )

        user1.reload
        expect(user1.automatch_time).to eq(30.minutes.from_now)
      end
    end

    it 'sets automatch time for specific time' do
      Timecop.freeze(DateTime.parse('2016-1-1')) do
        expect(message: "#{SlackRubyBot.config.user} automatch until June 20th, 2016 at 8pm", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
          'Automatch is on for username (1 users ready to play!)'
        )

        user1.reload
        expect(user1.automatch_time).to eq(DateTime.parse('2016-06-20 20:00-07:00'))
      end
    end

    it 'indicates when the time cannot be interpreted' do
      expect(message: "#{SlackRubyBot.config.user} automatch until the cows come home", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
        "Can't understand time specified"
      )
    end
  end

  context 'for' do
    it 'sets automatch time for relative time' do
      Timecop.freeze(Time.now.beginning_of_minute) do
        expect(message: "#{SlackRubyBot.config.user} automatch for 2 hours", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
          'Automatch is on for username (1 users ready to play!)'
        )

        user1.reload
        expect(user1.automatch_time).to eq(2.hours.from_now)
      end
    end

    it 'indicates when the time cannot be interpreted' do
      expect(message: "#{SlackRubyBot.config.user} automatch for a really really long time", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
        "Can't understand time specified"
      )
    end
  end

  context 'with no arguments' do
    it 'lists users and the times they are set to automatch until' do
      Timecop.freeze(Time.now.beginning_of_minute) do
        user1.automatch_time = 4.minutes.from_now
        user1.save

        user2.automatch_time = 1.hour.from_now
        user2.save

        expect(message: "#{SlackRubyBot.config.user} automatch", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
          "username for 4 mins 0 secs\nusername2 for 1 hr 0 secs"
        )
      end
    end

    it 'does not include users with times set in the past' do
      Timecop.freeze(Time.now.beginning_of_minute) do
        user1.automatch_time = 4.minutes.from_now
        user1.save

        user2.automatch_time = 1.minute.ago
        user2.save

        expect(message: "#{SlackRubyBot.config.user} automatch", user: user1.user_id, channel: 'pongbot').to respond_with_slack_message(
          "username for 4 mins 0 secs"
        )
      end
    end
  end
end
