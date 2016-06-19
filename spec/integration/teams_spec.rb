require 'spec_helper'

describe 'Teams', js: true, type: :feature do
  context 'oauth', vcr: { cassette_name: 'auth_test' } do
    before do
      Fabricate(:game, name: 'pong')
    end
    it 'registers a team' do
      allow_any_instance_of(Team).to receive(:ping!).and_return(ok: true)
      expect(SlackGamebot::Service.instance).to receive(:start!)
      oauth_access = { 'bot' => { 'bot_access_token' => 'token' }, 'team_id' => 'team_id', 'team_name' => 'team_name' }
      allow_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(hash_including(code: 'code')).and_return(oauth_access)
      expect do
        visit '/?code=code&game=pong'
        expect(page.find('#messages')).to have_content 'Team successfully registered!'
      end.to change(Team, :count).by(1)
    end
  end
end
