RSpec.configure do |config|
  config.before do
    allow(Stripe).to receive(:api_key).and_return('key')
  end
end
