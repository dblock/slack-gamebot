namespace :ps do
  namespace :web do
    desc 'Run web application.'
    task :run, [:port] => :environment do |_, args|
      args.with_defaults(port: ENV['PORT'] || 5000)
      require 'rack/handler/puma'
      NewRelic::Agent.manual_start
      Rack::Handler::Puma.run Api::Middleware.instance, Port: args[:port]
    end
  end

  namespace :worker do
    desc 'Run bot application.'
    task run: :environment do
      NewRelic::Agent.manual_start
      SlackGamebot::App.instance.prepare!
      EM.run do
        SlackGamebot::Service.start_from_database!
      end
    end
  end
end
