source 'http://rubygems.org'

ruby '2.1.6'

gem 'hashie'
gem 'slack-api', '~> 1.1.6', require: 'slack'
gem 'mongoid', '~> 4.x'
gem 'ruby-enum'
gem 'giphy', '~> 2.0.2'
gem 'puma'
gem 'grape', github: 'intridea/grape'
gem 'grape-roar'
gem 'rack-cors'
gem 'kaminari', '~> 0.16.1', require: 'kaminari/grape'
gem 'grape-swagger'

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
