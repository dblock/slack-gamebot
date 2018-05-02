require 'rubygems'
require 'bundler'

Bundler.setup :default, :development

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'tasks/logger'

unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    spec.exclude_pattern = 'spec/integration/**/*_spec.rb'
  end

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new

  task default: %i[rubocop spec]

  import 'tasks/db.rake'
end
