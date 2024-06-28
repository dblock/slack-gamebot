require 'spec_helper'

describe 'Homepage', :js, type: :feature do
  let!(:game) { Fabricate(:game, name: 'pong') }

  context 'v1' do
    before do
      visit '/?version=1'
    end

    it 'displays index.html page' do
      expect(title).to eq('PlayPlay.io - Ping Pong Bot, Chess Bot, Pool Bot and Tic Tac Toe Bot for Slack')
      click_link 'Add to Slack'
      expect(first('a[class=add-to-slack]')['href']).to eq "https://slack.com/oauth/authorize?scope=bot&client_id=#{game.client_id}"
    end
  end

  context 'v2' do
    before do
      visit '/'
    end

    it 'redirects' do
      expect(current_url).to eq('https://gamebot2.playplay.io/')
    end
  end
end
