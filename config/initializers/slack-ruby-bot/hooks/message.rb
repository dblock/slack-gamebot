module SlackRubyBot
  module Hooks
    module Message
      alias_method :_message, :message
      def message(client, data)
        _message client, data
      rescue Mongoid::Errors::Validations => e
        raise ArgumentError, e.document.errors.first[1]
      end
    end
  end
end
