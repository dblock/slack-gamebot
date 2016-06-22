RSpec.shared_context :stripe_mock do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before do
    StripeMock.start
  end
  after do
    StripeMock.stop
  end
end

RSpec.configure do |config|
  config.before do
    allow(Stripe).to receive(:api_key).and_return('key')
  end
end
