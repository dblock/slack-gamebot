RSpec.configure do |config|
  config.before :all do
    ENV['GAMEBOT_SECRET'] ||= 'secret'
  end
end
