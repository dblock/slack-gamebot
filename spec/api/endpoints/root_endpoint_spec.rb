require 'spec_helper'

describe Api::Endpoints::RootEndpoint do
  include Api::Test::EndpointTest

  it 'hypermedia root' do
    get '/'
    expect(last_response.status).to eq 200
    links = JSON.parse(last_response.body)['_links']
    expect(links.keys.sort).to eq(%w(self status team teams user users challenge challenges match matches current_season season seasons).sort)
  end
  it 'follows all links' do
    get '/'
    expect(last_response.status).to eq 200
    links = JSON.parse(last_response.body)['_links']
    links.each_pair do |_key, h|
      href = h['href']
      next if href.include?('{') # templated link
      get href.gsub('http://example.org', '')
      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body)).to_not eq({})
    end
  end
end
