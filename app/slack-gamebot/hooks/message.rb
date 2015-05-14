module SlackGamebot
  module Hooks
    module Message
      extend Base

      def message(data)
        data = Hashie::Mash.new(data)
        bot_name, command, arguments = parse_command(data.text)
        return unless bot_name == SlackGamebot.config.user
        klass = command_to_class(command || 'Default')
        klass.call data, command, arguments
      rescue Mongoid::Errors::Validations => e
        raise ArgumentError, e.document.errors.first[1]
      end

      private

      def parse_command(text)
        parts = text.split.reject(&:blank?) if text
        [parts.first.downcase, parts[1].try(:downcase), parts[2..parts.length]] if parts && parts.any?
      end

      def command_to_class(command)
        klass = "SlackGamebot::Commands::#{command.titleize}".constantize rescue nil
        klass || SlackGamebot::Commands::Unknown
      end
    end
  end
end
