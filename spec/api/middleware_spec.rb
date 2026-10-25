require 'spec_helper'

describe Api::Middleware do
  include Rack::Test::Methods

  let(:app) { described_class.instance }
  let(:game) { Fabricate(:game, name: 'chess') }
  let(:team) { Fabricate(:team, game: game) }

  %w[/ /privacy.html /subscribe.html /update_cc.html].each do |path|
    it "versions local assets and revalidates #{path}" do
      params = path == '/update_cc.html' ? { game: game.name, team_id: team.team_id } : {}
      get path, params

      assets = Capybara.string(last_response.body).all('script[src], link[href], img[src], meta[name="msapplication-TileImage"]', visible: :all)
      # Leave the pre-existing missing Android icon outside this upgrade.
      urls = assets.map { |asset| asset[:src] || asset[:href] || asset[:content] } - ['/android-icon-192x192.png']
      urls.reject! { |url| url.start_with?('http:', 'https:', '//') }
      expect(last_response.status).to eq 200
      expect(last_response.headers['Cache-Control']).to eq 'private, no-cache'
      expect(urls).not_to be_empty
      expect(urls).to all(match(%r{\A/.+\?v=[a-f0-9]{64}\z}))
    end
  end

  it 'versions game-specific Stripe images in JavaScript and HTML attributes' do
    image = "/img/chess.png?v=#{Digest::SHA256.file('public/img/chess.png').hexdigest}"
    get '/subscribe.html', game: game.name, team_id: team.team_id
    expect(last_response.body).to include("image: #{image.to_json}")

    get '/update_cc.html', game: game.name, team_id: team.team_id
    expect(Capybara.string(last_response.body).find('script[data-image]', visible: :all)['data-image']).to eq image
  end

  it 'revalidates CSS and regenerates nested artwork URLs after an image-only change' do
    get '/css/agency.css'
    image_hash = Digest::SHA256.file('public/img/header-bg.jpg').hexdigest
    expect(last_response.content_type).to eq 'text/css; charset=utf-8'
    expect(last_response.headers['Cache-Control']).to eq 'private, no-cache'
    expect(last_response.body).to include("/img/header-bg.jpg?v=#{image_hash}")

    allow(Digest::SHA256).to receive(:file).and_call_original
    allow(Digest::SHA256).to receive(:file).with('public/img/header-bg.jpg').and_return(double(hexdigest: 'f' * 64))
    get '/css/agency.css', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime('public/css/agency.css.erb').httpdate
    expect(last_response.status).to eq 200
    expect(last_response.body).to include("/img/header-bg.jpg?v=#{'f' * 64}")
    expect(last_response.body).not_to include(image_hash)
  end

  it 'retains content ETags and timestamp validation for static files' do
    get '/js/playplay.js'
    etag = last_response.headers['ETag']
    expect(etag).to eq %("#{Digest::SHA256.file('public/js/playplay.js').hexdigest}")
    expect(last_response.headers['Cache-Control']).to be_nil

    get '/js/playplay.js', {}, 'HTTP_IF_NONE_MATCH' => etag
    expect(last_response.status).to eq 304
    expect(last_response.body).to be_empty

    get '/js/playplay.js', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime('public/js/playplay.js').httpdate
    expect(last_response.status).to eq 304
  end

  it 'ignores a matching mtime when the content ETag is stale' do
    get '/js/playplay.js', {}, 'HTTP_IF_NONE_MATCH' => '"old-content"',
                               'HTTP_IF_MODIFIED_SINCE' => File.mtime('public/js/playplay.js').httpdate

    expect(last_response.status).to eq 200
    expect(last_response.body).to eq File.read('public/js/playplay.js')
  end
end
