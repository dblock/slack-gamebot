module SlackGamebot
  module Hooks
    module Hello
      extend Base

      def hello(_data)
        logger.info "Successfully connected to #{SlackGamebot.config.url}."
      end
    end
  end
end
