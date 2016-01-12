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
    context 'api' do
      it 'shows current value of API on' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is on!"
        )
      end
      it 'shows current value of API' do
        team.update_attributes!(api: false)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
      end
      it 'enables API' do
        expect(message: "#{SlackRubyBot.config.user} set api on").to respond_with_slack_message(
          "API for team #{team.name} is on!"
        )
        expect(team.reload.api).to be true
      end
      it 'disables API' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api off").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
        expect(team.reload.api).to be false
      end
    end
    context 'aliases' do
      context 'with aliases' do
        before do
          team.update_attributes!(aliases: %w(foo bar))
        end
        it 'shows current value of aliases' do
          expect(message: "#{SlackRubyBot.config.user} set aliases").to respond_with_slack_message(
            "Bot aliases for team #{team.name} are foo and bar."
          )
        end
        it 'sets aliases' do
          expect(message: "#{SlackRubyBot.config.user} set aliases foo bar baz").to respond_with_slack_message(
            "Bot aliases for team #{team.name} are foo, bar and baz."
          )
          expect(team.reload.aliases).to eq %w(foo bar baz)
          expect(app.send(:client).aliases).to eq %w(foo bar baz)
        end
        it 'sets comma-separated aliases with extra spaces' do
          expect(message: "#{SlackRubyBot.config.user} set aliases   foo,    bar").to respond_with_slack_message(
            "Bot aliases for team #{team.name} are foo and bar."
          )
          expect(team.reload.aliases).to eq %w(foo bar)
          expect(app.send(:client).aliases).to eq %w(foo bar)
        end
        it 'sets emoji aliases' do
          expect(message: "#{SlackRubyBot.config.user} set aliases pp :pong:").to respond_with_slack_message(
            "Bot aliases for team #{team.name} are pp and :pong:."
          )
          expect(team.reload.aliases).to eq ['pp', ':pong:']
        end
        it 'removes aliases' do
          expect(message: "#{SlackRubyBot.config.user} set aliases none").to respond_with_slack_message(
            "Team #{team.name} does not have any bot aliases."
          )
          expect(team.reload.aliases).to be_empty
          expect(app.send(:client).aliases).to be_empty
        end
      end
      context 'without aliases' do
        it 'shows no aliases' do
          expect(message: "#{SlackRubyBot.config.user} set aliases").to respond_with_slack_message(
            "Team #{team.name} does not have any bot aliases."
          )
        end
      end
    end
    context 'invalid' do
      it 'error' do
        expect(message: "#{SlackRubyBot.config.user} set invalid on").to respond_with_slack_message(
          'Invalid setting invalid, you can _set gifs on|off_ and _aliases_.'
        )
      end
    end
  end
  context 'not captain' do
    before do
      Fabricate(:user, team: team, captain: true)
      captain.demote!
    end
    context 'gifs' do
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
    context 'aliases' do
      it 'cannot set aliases' do
        expect(message: "#{SlackRubyBot.config.user} set aliases foo bar").to respond_with_slack_message(
          "You're not a captain, sorry."
        )
      end
      it 'can see aliases' do
        expect(message: "#{SlackRubyBot.config.user} set aliases").to respond_with_slack_message(
          "Team #{team.name} does not have any bot aliases."
        )
      end
    end
  end
end
