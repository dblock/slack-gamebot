module SlackGamebot
  module Hooks
    module UserChange
      extend SlackRubyBot::Hooks::Base

      def user_change(client, data)
        user = User.where(team: client.team, user_id: data.user.id).first
        return unless user && user.user_name != data.user.name
        logger.info "RENAME: #{user.user_id}, #{user.user_name} => #{data.user.name}"
        user.update_attributes!(user_name: data.user.name)
      end
    end
  end
end
