source 'http://rubygems.org'

ruby '2.3.1'

gem 'slack-ruby-bot-server', github: 'dblock/slack-ruby-bot-server'
gem 'ruby-enum'
gem 'mongoid-scroll'
gem 'time_ago_in_words'
gem 'rack-robotz'
gem 'wannabe_bool'
gem 'newrelic_rpm'
gem 'rack-server-pages'
gem 'stripe'

group :development, :test do
  gem 'rake', '~> 10.4'
  gem 'rubocop', '0.34.2'
  gem 'foreman'
  gem 'stripe-ruby-mock', require: 'stripe_mock'
end

group :development do
  gem 'mongoid-shell'
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
  gem 'excon'
  gem 'capybara'
  gem 'selenium-webdriver'
end
