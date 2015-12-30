require 'spec_helper'

describe SlackGamebot::Commands::Matches, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Team.first || Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:user) { Fabricate(:user, user_name: 'username') }
  let(:singles_challenge) { Fabricate(:challenge, challengers: [user]) }
  let(:doubles_challenge) { Fabricate(:doubles_challenge, challengers: [user, Fabricate(:user)]) }
  context 'with many matches' do
    let!(:match0) { Fabricate(:match) }
    let!(:match1) { Fabricate(:match, challenge: doubles_challenge) }
    let!(:match2) { Fabricate(:match, challenge: doubles_challenge) }
    let!(:match3) { Fabricate(:match, challenge: doubles_challenge) }
    it 'displays all matches' do
      expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: match1.challenge.channel).to respond_with_slack_message([
        "#{match1} 3 times",
        "#{match0} once"
      ].join("\n"))
    end
    it 'displays only matches for requested users' do
      expect(message: "#{SlackRubyBot.config.user} matches #{match1.challenge.challenged.first.user_name}", user: user.user_id, channel: match1.challenge.channel).to respond_with_slack_message(
        "#{match1} 3 times"
      )
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:team2_match) { Fabricate(:match, team: team2) }
      it 'displays only matches for requested users' do
        expect(message: "#{SlackRubyBot.config.user} matches #{match1.challenge.challenged.first.user_name}", user: user.user_id, channel: match1.challenge.channel).to respond_with_slack_message(
          "#{match1} 3 times"
        )
      end
    end
  end
  context 'with a doubles match' do
    let!(:match) { Fabricate(:match, challenge: doubles_challenge) }
    it 'displays user matches' do
      expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: match.challenge.channel).to respond_with_slack_message(
        "#{match} once"
      )
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:team2_match) { Fabricate(:match, team: team2) }
      it 'displays user matches' do
        expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: match.challenge.channel).to respond_with_slack_message(
          "#{match} once"
        )
      end
    end
  end
  context 'with a singles match' do
    let!(:match) { Fabricate(:match, challenge: singles_challenge) }
    it 'displays user matches' do
      expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: match.challenge.channel).to respond_with_slack_message(
        "#{match} once"
      )
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:team2_match) { Fabricate(:match, team: team2) }
      it 'displays user matches' do
        expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: match.challenge.channel).to respond_with_slack_message(
          "#{match} once"
        )
      end
    end
  end
  context 'without matches' do
    it 'displays' do
      expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: 'channel').to respond_with_slack_message('Nothing to see here.')
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:team2_match) { Fabricate(:match, team: team2) }
      it 'displays matches for team 1' do
        expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: 'channel').to respond_with_slack_message('Nothing to see here.')
      end
    end
  end
  context 'matches in prior seasons' do
    let!(:match1) { Fabricate(:match, challenge: singles_challenge) }
    let!(:season) { Fabricate(:season) }
    let(:singles_challenge2) { Fabricate(:challenge, challengers: [user]) }
    let!(:match2) { Fabricate(:match, challenge: singles_challenge2) }
    it 'displays user matches in current season only' do
      expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: match2.challenge.channel).to respond_with_slack_message(
        "#{match2} once"
      )
    end
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      let!(:team2_match) { Fabricate(:match, team: team2) }
      it 'displays user matches in current season only' do
        expect(message: "#{SlackRubyBot.config.user} matches", user: user.user_id, channel: match2.challenge.channel).to respond_with_slack_message(
          "#{match2} once"
        )
      end
    end
  end
end
