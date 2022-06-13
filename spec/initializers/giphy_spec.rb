require 'spec_helper'

describe Giphy, js: true, type: :feature do
  context 'with GIPHY_API_KEY' do
    before do
      ENV['GIPHY_API_KEY'] = 'key'
    end
    after do
      ENV.delete('GIPHY_API_KEY')
    end
    it 'returns a random gif', vcr: { cassette_name: 'giphy_random' } do
      expect(Giphy.random('bot')).to eq 'https://media4.giphy.com/media/QAPGorQJSoarrsjVhH/200.gif'
    end
  end
end
