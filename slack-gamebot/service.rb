module SlackGamebot
  class Service < SlackRubyBotServer::Service
    def self.instance
      SlackRubyBotServer::Service.instance(server_class: SlackGamebot::Server)
    end
  end
end
