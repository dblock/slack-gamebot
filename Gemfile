source 'http://rubygems.org'

ruby '2.2.4'

gem 'slack-ruby-bot', '~> 0.5.3'
gem 'mongoid', '~> 5.0.0'
gem 'ruby-enum'
gem 'puma'
gem 'grape', '~> 0.13.0'
gem 'grape-roar'
gem 'rack-cors'
gem 'kaminari', '~> 0.16.1', require: 'kaminari/grape'
gem 'grape-swagger'
gem 'mongoid-scroll'
gem 'time_ago_in_words'
gem 'rack-robotz'
gem 'newrelic_rpm'
gem 'newrelic-slack-ruby-bot'
gem 'rack-rewrite'

group :development, :test do
  gem 'rake', '~> 10.4'
  gem 'rubocop', '0.34.2'
  gem 'foreman'
end

group :development do
  gem 'mongoid-shell'
  gem 'heroku'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'webmock'
  gem 'vcr'
  gem 'fabrication'
  gem 'faker'
  gem 'database_cleaner'
  gem 'hyperclient'
end
