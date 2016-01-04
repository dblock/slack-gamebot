require 'spec_helper'

describe SlackGamebot::Commands::Set, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:captain) { Fabricate(:user, team: team, user_name: 'username', captain: true) }
  context 'captain' do
    it 'gives help' do
      expect(message: "#{SlackRubyBot.config.user} set").to respond_with_slack_message(
        'Missing setting, eg. _set gifs off_.'
      )
    end
    context 'gifs' do
      it 'shows current value of GIFs on' do
        expect(message: "#{SlackRubyBot.config.user} set gifs").to respond_with_slack_message(
          "GIFs for team #{team.name} are on!"
        )
      end
      it 'shows current value of GIFs off' do
        team.update_attributes!(gifs: false)
        expect(message: "#{SlackRubyBot.config.user} set gifs").to respond_with_slack_message(
          "GIFs for team #{team.name} are off."
        )
      end
      it 'enables GIFs' do
        team.update_attributes!(gifs: false)
        expect(message: "#{SlackRubyBot.config.user} set gifs on").to respond_with_slack_message(
          "GIFs for team #{team.name} are on!"
        )
        expect(team.reload.gifs).to be true
        expect(app.send(:client).send_gifs?).to be true
      end
      it 'disables GIFs' do
        team.update_attributes!(gifs: true)
        expect(message: "#{SlackRubyBot.config.user} set gifs off").to respond_with_slack_message(
          "GIFs for team #{team.name} are off."
        )
        expect(team.reload.gifs).to be false
        expect(app.send(:client).send_gifs?).to be false
      end
    end
    context 'invalid' do
      it 'error' do
        expect(message: "#{SlackRubyBot.config.user} set invalid on").to respond_with_slack_message(
          'Invalid setting invalid, you can _set gifs on|off_.'
        )
      end
    end
  end
  context 'not captain' do
    before do
      Fabricate(:user, team: team, captain: true)
      captain.demote!
    end
    it 'cannot set GIFs' do
      expect(message: "#{SlackRubyBot.config.user} set gifs true").to respond_with_slack_message(
        "You're not a captain, sorry."
      )
    end
    it 'can see GIFs value' do
      expect(message: "#{SlackRubyBot.config.user} set gifs").to respond_with_slack_message(
        "GIFs for team #{team.name} are on!"
      )
    end
  end
end
