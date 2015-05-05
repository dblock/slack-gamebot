module SlackGamebot
  module Hooks
    module UserChange
      extend Base

      def user_change(data)
        data = Hashie::Mash.new(data)
        user = User.where(user_id: data.user.id).first
        return unless user && user.user_name != data.user.name
        logger.info "Renaming #{user.user_id}: #{user.user_name} => #{data.user.name}"
        user.update_attributes!(user_name: data.user.name)
      end
    end
  end
end
