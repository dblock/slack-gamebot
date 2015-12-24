module SlackGamebot
  class Server < SlackRubyBot::Server
    include SlackGamebot::Hooks::UserChange

    attr_accessor :team

    def initialize(attrs = {})
      @team = attrs[:team]
      fail 'Missing team' unless @team
      super(token: @team.token)
      client.team = @team
    end

    def restart!(_wait = 1)
      logger.info "#{team.name}: socket closed, ignoring restart."
    end
  end
end
