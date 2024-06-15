require 'database_cleaner-mongoid'

RSpec.configure do |config|
  config.before :suite do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with :deletion
  end

  config.after :suite do
    Mongoid.purge!
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
