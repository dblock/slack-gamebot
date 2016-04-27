module SlackGamebot
  class Server < SlackRubyBot::Server
    include SlackGamebot::Hooks::UserChange

    attr_accessor :team

    def initialize(attrs = {})
      @team = attrs[:team]
      fail 'Missing team' unless @team
      options = { token: @team.token }
      options[:aliases] = ([team.game.name] + [team.aliases]).flatten.compact
      options[:send_gifs] = team.gifs
      super(options)
      client.owner = @team
    end

    def restart!(wait = 1)
      # when an integration is disabled, a live socket is closed, which causes the default behavior of the client to restart
      # it would keep retrying without checking for account_inactive or such, we want to restart via service which will disable an inactive team
      EM.defer do
        logger.info "#{team.name}: socket closed, restarting ..."
        SlackGamebot::Service.restart! team, self, wait
        client.owner = team
      end
    end
  end
end
