require 'spec_helper'

describe SlackGamebot::Commands::Rank, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  shared_examples_for 'rank' do
    let!(:user_elo_12) { Fabricate(:user, elo: 12, wins: 0, losses: 25) }
    let!(:user_elo_38) { Fabricate(:user, elo: 38, wins: 3, losses: 3) }
    let!(:user_elo_42) { Fabricate(:user, elo: 42, wins: 3, losses: 2) }
    let!(:user_elo_67) { Fabricate(:user, elo: 67, wins: 5, losses: 2) }
    let!(:user_elo_98) { Fabricate(:user, elo: 98, wins: 7, losses: 0) }
    it 'ranks the requester if no argument is passed' do
      expect(message: "#{SlackRubyBot.config.user} rank", user: user_elo_42.user_id).to respond_with_slack_message '3. username: 3 wins, 2 losses (elo: 42)'
    end
    it 'ranks someone who is not ranked' do
      user = Fabricate(:user, team: team)
      expect(message: "#{SlackRubyBot.config.user} rank", user: user.user_id).to respond_with_slack_message 'username: not ranked'
    end
    it 'ranks someone who is not ranked by default' do
      user1 = Fabricate(:user, team: team)
      Fabricate(:user, team: team)
      expect(message: "#{SlackRubyBot.config.user} rank", user: user1.user_id).to respond_with_slack_message 'username: not ranked'
    end
    it 'ranks someone who is not ranked by name' do
      user1 = Fabricate(:user, team: team)
      Fabricate(:user, team: team)
      expect(message: "#{SlackRubyBot.config.user} rank #{user1.user_name}", user: user1.user_id).to respond_with_slack_message "#{user1.user_name}: not ranked"
    end
    it 'ranks one player by slack mention' do
      expect(message: "#{SlackRubyBot.config.user} rank #{user_elo_42.slack_mention}").to respond_with_slack_message "3. #{user_elo_42}"
    end
    it 'ranks one player by user_id' do
      expect(message: "#{SlackRubyBot.config.user} rank <@#{user_elo_42.user_id}>").to respond_with_slack_message "3. #{user_elo_42}"
    end
    it 'shows the smallest range of ranks for a list of players' do
      users = [user_elo_38, user_elo_67].map(&:slack_mention)
      expect(message: "#{SlackRubyBot.config.user} rank #{users.join(' ')}").to respond_with_slack_message "2. #{user_elo_67}\n3. #{user_elo_42}\n4. #{user_elo_38}"
    end
  end
  it_behaves_like 'rank'
  context 'with another team' do
    let!(:team2) { Fabricate(:team) }
    let!(:user2_elo_42) { Fabricate(:user, team: team2, elo: 42, wins: 3, losses: 2) }
    let!(:user2_elo_48) { Fabricate(:user, team: team2, elo: 48, wins: 2, losses: 3) }
    it_behaves_like 'rank'
  end
end
