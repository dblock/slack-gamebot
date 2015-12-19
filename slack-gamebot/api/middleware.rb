module Api
  class Middleware
    def self.logger
      @logger ||= begin
        $stdout.sync = true
        Logger.new(STDOUT)
      end
    end

    def self.instance
      @instance ||= Rack::Builder.new do
        use Rack::Cors do
          allow do
            origins '*'
            resource '*', headers: :any, methods: [:get, :post]
          end
        end

        run Api::Middleware.new
      end.to_app
    end

    def call(env)
      Api::Endpoints::RootEndpoint.call(env)
    end
  end
end
