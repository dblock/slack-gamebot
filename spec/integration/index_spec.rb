require 'spec_helper'

describe 'index.html', js: true, type: :feature do
  let!(:game) { Fabricate(:game, name: 'pong') }
  before do
    visit '/'
  end
  it 'includes a link to add to slack with the client id' do
    expect(title).to eq('PlayPlay.io - Ping Pong Bot, Chess Bot, Pool Bot and Tic Tac Toe Bot for Slack')
    click_link 'Add to Slack'
    expect(first('a[class=add-to-slack]')['href']).to eq "https://slack.com/oauth/authorize?scope=bot&client_id=#{game.client_id}"
  end
end
