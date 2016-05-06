module SlackGamebot
  class Server < SlackRubyBot::Server
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
      logger.info "#{team.name}: socket closed, restarting ..."
      SlackGamebot::Service.instance.restart! team, self, wait
      client.owner = team
    end

    on :user_change do |client, data|
      user = User.where(team: client.owner, user_id: data.user.id).first
      next unless user && user.user_name != data.user.name
      logger.info "RENAME: #{user.user_id}, #{user.user_name} => #{data.user.name}"
      user.update_attributes!(user_name: data.user.name)
    end
  end
end
