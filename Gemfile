source 'http://rubygems.org'

ruby '2.1.6'

gem 'hashie'
gem 'slack-api', github: 'aki017/slack-ruby-gem', require: 'slack'
gem 'mongoid', '~> 4.x'
gem 'ruby-enum'
gem 'giphy', github: 'dblock/giphy', branch: 'handle-errors-and-redirects'
gem 'puma'
gem 'grape-roar'
gem 'rack-cors'
gem 'kaminari', '~> 0.16.1', require: 'kaminari/grape'

group :development, :test do
  gem 'rake', '~> 10.4'
  gem 'rubocop', '0.30.0'
  gem 'foreman'
end

group :test do
  gem 'rspec', '~> 3.2'
  gem 'webmock'
  gem 'vcr'
  gem 'fabrication'
  gem 'faker'
  gem 'database_cleaner', '~> 1.4'
  gem 'hyperclient'
  gem 'rack-test', '~> 0.6.2'
end
