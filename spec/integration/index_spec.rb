require 'spec_helper'

describe 'index.html', :js, type: :feature do
  let!(:game) { Fabricate(:game, name: 'pong') }

  context 'v1' do
    before do
      visit '/?version=1'
    end

    it 'includes a link to add to slack with the client id' do
      expect(title).to eq('PlayPlay.io - Ping Pong Bot, Chess Bot, Pool Bot and Tic Tac Toe Bot for Slack')
      click_link 'Add to Slack'
      expect(first('a[class=add-to-slack]')['href']).to eq "https://slack.com/oauth/authorize?scope=bot&client_id=#{game.client_id}"
    end
  end

  context 'v2', driver: :selenium_no_wait do
    it 'redirects' do
      visit '/'
      expect(page).to have_current_path('https://gamebot2.playplay.io/', url: true)
    end
  end
end
