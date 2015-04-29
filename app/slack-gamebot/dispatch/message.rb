module SlackGamebot
  module Dispatch
    module Message
      extend Hook

      def message(data)
        data = Hashie::Mash.new(data)
        bot_name, command, arguments = SlackGamebot::Dispatch::Message.parse_command(data.text)
        case command
        when nil
          SlackGamebot::Dispatch::Message.message data.channel, SlackGamebot::ASCII
        when 'hi'
          SlackGamebot::Dispatch::Message.message data.channel, "Hi <@#{data.user}>!"
        when 'register'
          SlackGamebot::Dispatch::Message.register_user data
        else
          SlackGamebot::Dispatch::Message.message data.channel, "Sorry <@#{data.user}>, I don't understand that command!"
        end if bot_name == SlackGamebot.config.user
      end

      private

      def self.register_user(data)
        user = User.where(user_id: data.user).first
        user_info = Hashie::Mash.new(Slack.users_info(user: data.user)).user
        if user && user.user_name != user_info.name
          user.update_attributes!(user_name: user_info.name)
          SlackGamebot::Dispatch::Message.message data.channel, "Welcome back <@#{data.user}>, I've updated your registration."
        elsif user && user.user_name == user_info.name
          SlackGamebot::Dispatch::Message.message data.channel, "Welcome back <@#{data.user}>, you're already registered."
        else
          user = User.create!(user_id: data.user, user_name: user_info.name)
          SlackGamebot::Dispatch::Message.message data.channel, "Welcome <@#{data.user}>! You're ready to play."
        end
        user
      end

      def self.parse_command(text)
        parts = text.gsub(/[^[:word:]\s]/, '').split.reject(&:blank?) if text
        bot_name = parts.first if parts
        [bot_name, parts[1], parts[2..parts.length]]
      end

      def self.message(channel, text)
        Slack.chat_postMessage(channel: channel, text: text)
      end
    end
  end
end
