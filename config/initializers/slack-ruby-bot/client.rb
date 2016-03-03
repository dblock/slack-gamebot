module SlackRubyBot
  class Client < Slack::RealTime::Client
    # keep track of the team that the client is connected to
    attr_accessor :owner

    alias_method :_build_socket, :build_socket
    def build_socket
      @store_class = Slack::RealTime::Stores::Starter
      _build_socket
    end
  end
end
