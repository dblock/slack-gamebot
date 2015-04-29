module SlackGamebot
  module Dispatch
    module Hello
      extend Hook

      def hello(_data)
        logger.info "Successfully connected to #{SlackGamebot.config.url}."
      end
    end
  end
end
