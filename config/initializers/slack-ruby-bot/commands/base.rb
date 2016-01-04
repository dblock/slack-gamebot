require 'slack-gamebot/error'

module SlackRubyBot
  module Commands
    class Base
      class << self
        alias_method :_invoke, :invoke

        def invoke(client, data)
          _invoke client, data
        rescue Mongoid::Errors::Validations => e
          logger.info "#{name.demodulize.upcase}: #{client.team}, error - #{e.document.errors.first[1]}"
          send_message_with_gif client, data.channel, e.document.errors.first[1], 'error'
          true
        rescue SlackGamebot::Error => e
          logger.info "#{name.demodulize.upcase}: #{client.team}, error - #{e}"
          send_message_with_gif client, data.channel, e.message, 'error'
          true
        end
      end
    end
  end
end
