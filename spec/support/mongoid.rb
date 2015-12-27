Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO

RSpec.configure do |config|
  config.before :suite do
    ::Mongoid::Tasks::Database.create_indexes
  end
end
