module SlackGamebot
  module Commands
    class Base
      def self.send_message(channel, text)
        Slack.chat_postMessage(channel: channel, text: text)
      end

      def self.send_message_with_gif(channel, text, keywords)
        gif = Giphy.random(keywords)
        text = text + "\n" + gif.image_url.to_s if gif
        send_message channel, text
      end
    end
  end
end
