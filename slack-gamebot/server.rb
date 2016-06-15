# TODO: remove after https://github.com/dblock/slack-ruby-bot-server/issues/21
module SlackRubyBotServer
  class Server < SlackRubyBot::Server
    def initialize(attrs = {})
      @team = attrs[:team]
      fail 'Missing team' unless @team
      options = { token: @team.token }.merge(attrs)
      super(options)
      client.owner = @team
    end
  end
end

module SlackGamebot
  class Server < SlackRubyBotServer::Server
    def initialize(attrs = {})
      attrs = attrs.dup
      attrs[:aliases] = ([attrs[:team].game.name] + [attrs[:team].aliases]).flatten.compact
      attrs[:send_gifs] = attrs[:team].gifs
      super attrs
    end

    on :user_change do |client, data|
      user = User.where(team: client.owner, user_id: data.user.id).first
      next unless user && user.user_name != data.user.name
      logger.info "RENAME: #{user.user_id}, #{user.user_name} => #{data.user.name}"
      user.update_attributes!(user_name: data.user.name)
    end
  end
end
