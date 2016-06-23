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
