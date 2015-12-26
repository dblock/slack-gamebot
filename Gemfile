source 'http://rubygems.org'

ruby '2.2.1'

gem 'slack-ruby-bot', github: 'dblock/slack-ruby-bot'
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

group :development, :test do
  gem 'rake', '~> 10.4'
  gem 'rubocop', '0.34.2'
  gem 'foreman'
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
