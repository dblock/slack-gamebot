require 'spec_helper'

describe 'index.html', js: true, type: :feature do
  before do
    visit '/'
  end
  it 'displays index.html page' do
    expect(title).to eq('PlayPlay.io - Ping Pong Bot, Chess Bot, Pool Bot and Tic Tac Toe Bot for Slack')
  end
  it 'includes a link to add to slack with the client id' do
    expect(find("a[href='https://slack.com/oauth/authorize?scope=bot&client_id=17032864353.17033629782']"))
  end
end
