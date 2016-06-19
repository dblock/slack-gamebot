require 'spec_helper'

describe 'privacy.html', js: true, type: :feature do
  before do
    visit '/privacy'
  end
  it 'displays privacy.html page' do
    expect(title).to eq('PlayPlay.io - Privacy Policy')
  end
end
