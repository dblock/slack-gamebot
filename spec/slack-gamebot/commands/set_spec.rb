require 'spec_helper'

describe SlackGamebot::Commands::Set, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackGamebot::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:captain) { Fabricate(:user, team: team, user_name: 'username', captain: true) }
  let(:message_hook) { SlackRubyBot::Hooks::Message.new }
  context 'captain' do
    it 'gives help' do
      expect(message: "#{SlackRubyBot.config.user} set").to respond_with_slack_message(
        'Missing setting, eg. _set gifs off_.'
      )
    end
    context 'gifs' do
      it 'is a premium feature' do
        expect(client).to receive(:say).with(channel: 'channel', text: team.premium_text)
        expect(client).to receive(:say).with(channel: 'channel', text: "GIFs for team #{team.name} are on!", gif: 'fun')
        message_hook.call(client, Hashie::Mash.new(channel: 'channel', user: 'user', text: "#{SlackRubyBot.config.user} set gifs on"))
      end
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
      context 'premium team' do
        let!(:team) { Fabricate(:team, premium: true) }
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
    end
    context 'api' do
      it 'is a premium feature' do
        expect(client).to receive(:say).with(channel: 'channel', text: team.premium_text)
        expect(client).to receive(:say).with(channel: 'channel', text: "API for team #{team.name} is on!", gif: 'programmer')
        message_hook.call(client, Hashie::Mash.new(channel: 'channel', user: 'user', text: "#{SlackRubyBot.config.user} set api on"))
      end
      it 'shows current value of API on' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is on!"
        )
      end
      it 'shows current value of API off' do
        team.update_attributes!(api: false)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
      end
      context 'premium team' do
        let!(:team) { Fabricate(:team, premium: true) }
        it 'shows current value of API on' do
          team.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            "API for team #{team.name} is on!"
          )
        end
        it 'shows current value of API off' do
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
        context 'with API_URL' do
          before do
            ENV['API_URL'] = 'http://local.api'
          end
          after do
            ENV.delete 'API_URL'
          end
          it 'shows current value of API on with API URL' do
            team.update_attributes!(api: true)
            expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
              "API for team #{team.name} is on!\nhttp://local.api/teams/#{team.id}"
            )
          end
          it 'shows current value of API off without API URL' do
            team.update_attributes!(api: false)
            expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
              "API for team #{team.name} is off."
            )
          end
        end
      end
    end
    context 'aliases' do
      it 'is a premium feature' do
        expect(client).to receive(:say).with(channel: 'channel', text: team.premium_text)
        expect(client).to receive(:say).with(channel: 'channel', text: "API for team #{team.name} is on!", gif: 'programmer')
        message_hook.call(client, Hashie::Mash.new(channel: 'channel', user: 'user', text: "#{SlackRubyBot.config.user} set api on"))
      end
      context 'with aliases' do
        before do
          team.update_attributes!(aliases: %w(foo bar))
        end
        it 'shows current value of aliases' do
          expect(message: "#{SlackRubyBot.config.user} set aliases").to respond_with_slack_message(
            "Bot aliases for team #{team.name} are foo and bar."
          )
        end
      end
      context 'premium team' do
        let!(:team) { Fabricate(:team, premium: true) }
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
          it 'sets comma-separated aliases' do
            expect(message: "#{SlackRubyBot.config.user} set aliases foo,bar").to respond_with_slack_message(
              "Bot aliases for team #{team.name} are foo and bar."
            )
            expect(team.reload.aliases).to eq %w(foo bar)
            expect(app.send(:client).aliases).to eq %w(foo bar)
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
    end
    context 'elo' do
      it 'is a premium feature' do
        expect(client).to receive(:say).with(channel: 'channel', text: team.premium_text)
        expect(client).to receive(:say).with(channel: 'channel', text: "Base elo for team #{team.name} is 0.", gif: 'score')
        message_hook.call(client, Hashie::Mash.new(channel: 'channel', user: 'user', text: "#{SlackRubyBot.config.user} set elo 1000"))
      end
      context 'with a non-default base elo' do
        before do
          team.update_attributes!(elo: 1000)
        end
        it 'shows current value of elo' do
          expect(message: "#{SlackRubyBot.config.user} set elo").to respond_with_slack_message(
            "Base elo for team #{team.name} is 1000."
          )
        end
      end
      context 'premium team' do
        let!(:team) { Fabricate(:team, premium: true) }
        context 'with a non-default base elo' do
          before do
            team.update_attributes!(elo: 1000)
          end
          it 'shows current value of elo' do
            expect(message: "#{SlackRubyBot.config.user} set elo").to respond_with_slack_message(
              "Base elo for team #{team.name} is 1000."
            )
          end
          it 'sets elo' do
            expect(message: "#{SlackRubyBot.config.user} set elo 200").to respond_with_slack_message(
              "Base elo for team #{team.name} is 200."
            )
            expect(team.reload.elo).to eq 200
          end
          it 'ignores errors' do
            expect(message: "#{SlackRubyBot.config.user} set elo invalid").to respond_with_slack_message(
              "Base elo for team #{team.name} is 1000."
            )
            expect(team.reload.elo).to eq 1000
          end
          it 'resets elo' do
            expect(message: "#{SlackRubyBot.config.user} set elo 0").to respond_with_slack_message(
              "Base elo for team #{team.name} is 0."
            )
            expect(team.reload.elo).to eq 0
          end
        end
      end
    end
    context 'invalid' do
      it 'error' do
        expect(message: "#{SlackRubyBot.config.user} set invalid on").to respond_with_slack_message(
          'Invalid setting invalid, you can _set gifs on|off_, _api on|off_ and _aliases_.'
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
  context 'nickname' do
    let(:user) { Fabricate(:user, team: team, user_name: 'username') }
    it 'is a premium feature' do
      expect(client).to receive(:say).with(channel: 'channel', text: team.premium_text)
      expect(client).to receive(:say).with(channel: 'channel', text: "You don't have a nickname set, #{user.user_name}.", gif: 'anonymous')
      message_hook.call(client, Hashie::Mash.new(channel: 'channel', user: 'user', text: "#{SlackRubyBot.config.user} set nickname bob"))
    end
    context 'with no nickname' do
      it 'shows that the user has no nickname' do
        expect(message: "#{SlackRubyBot.config.user} set nickname", user: user.user_id).to respond_with_slack_message(
          "You don't have a nickname set, #{user.user_name}."
        )
      end
    end
    context 'premium team' do
      let!(:team) { Fabricate(:team, premium: true) }
      context 'without a nickname set' do
        it 'sets nickname' do
          expect(message: "#{SlackRubyBot.config.user} set nickname john doe", user: user.user_id).to respond_with_slack_message(
            "Your nickname is now *john doe*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq 'john doe'
        end
        it 'sets emoji nickname' do
          expect(message: "#{SlackRubyBot.config.user} set nickname :dancer:", user: user.user_id).to respond_with_slack_message(
            "Your nickname is now *:dancer:*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq ':dancer:'
        end
      end
      context 'with a nickname set' do
        before do
          user.update_attributes!(nickname: 'bob')
        end
        it 'shows current value of nickname' do
          expect(message: "#{SlackRubyBot.config.user} set nickname", user: user.user_id).to respond_with_slack_message(
            "Your nickname is *bob*, #{user.slack_mention}."
          )
        end
        it 'sets nickname' do
          expect(message: "#{SlackRubyBot.config.user} set nickname john doe", user: user.user_id).to respond_with_slack_message(
            "Your nickname is now *john doe*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq 'john doe'
        end
        it 'cannot set nickname unless captain' do
          expect(message: "#{SlackRubyBot.config.user} set nickname #{captain.slack_mention} :dancer:", user: user.user_id).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end
        it 'sets nickname for another user' do
          expect(message: "#{SlackRubyBot.config.user} set nickname #{user.slack_mention} john doe", user: captain.user_id).to respond_with_slack_message(
            "Your nickname is now *john doe*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq 'john doe'
        end
      end
    end
  end
end
