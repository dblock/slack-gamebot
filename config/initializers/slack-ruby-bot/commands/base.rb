# monkeypatching send_message_with_gif to allow disabling of gifs
module SlackRubyBot
  module Commands
    class Base
      class << self
        alias_method :_old_send_message_with_gif, :send_message_with_gif

        def send_message_with_gif(client, channel, text, keywords, options = {})
          if SlackGamebot.config.enable_gifs
            _old_send_message_with_gif(client, channel, text, keywords, options)
          else
            send_message(client, channel, text, options)
          end
        end
      end
    end
  end
end
