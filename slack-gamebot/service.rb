module SlackRubyBotServer
  class Service
    def self.url
      ENV['URL'] || (ENV['RACK_ENV'] == 'development' ? 'http://localhost:5000' : 'https://www.playplay.io')
    end

    def self.api_url
      ENV['API_URL'] || "#{url}/api"
    end
  end
end
