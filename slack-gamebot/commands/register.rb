module SlackGamebot
  module Commands
    class Register < SlackRubyBot::Commands::Base
      def self.call(data, _command, _arguments)
        ts = Time.now.utc
        user = ::User.find_create_or_update_by_slack_id!(data.user)
        message = if user.created_at >= ts
                    "Welcome <@#{data.user}>! You're ready to play."
                  elsif user.updated_at >= ts
                    "Welcome back <@#{data.user}>, I've updated your registration."
                  else
                    "Welcome back <@#{data.user}>, you're already registered."
        end
        send_message_with_gif data.channel, message, 'welcome'
        user
      end
    end
  end
end
