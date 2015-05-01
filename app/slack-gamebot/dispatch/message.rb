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
          SlackGamebot::Dispatch::Message.message_with_gif data.channel, "Hi <@#{data.user}>!", 'hi'
        when 'register'
          SlackGamebot::Dispatch::Message.register_user data
        when 'challenge'
          SlackGamebot::Dispatch::Message.challenge data, command, arguments
        when 'accept'
          SlackGamebot::Dispatch::Message.accept_challenge data
        when 'decline'
          SlackGamebot::Dispatch::Message.decline_challenge data
        when 'cancel'
          SlackGamebot::Dispatch::Message.cancel_challenge data
        when 'lost'
          SlackGamebot::Dispatch::Message.lose_challenge data
        when 'leaderboard'
          SlackGamebot::Dispatch::Message.leaderboard data, arguments
        when 'help'
          SlackGamebot::Dispatch::Message.message_with_gif data.channel, 'See https://github.com/dblock/slack-gamebot, please.', 'help'
        else
          SlackGamebot::Dispatch::Message.message_with_gif data.channel, "Sorry <@#{data.user}>, I don't understand that command!", 'idiot'
        end if bot_name == SlackGamebot.config.user
      rescue Mongoid::Errors::Validations => e
        raise ArgumentError, e.document.errors.first[1]
      end

      private

      def self.challenge(data, _command, arguments)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.create_from_teammates_and_opponents!(challenger, arguments)
        SlackGamebot::Dispatch::Message.message_with_gif data.channel, "#{challenge.challengers.map(&:user_name).join(' and ')} challenged #{challenge.challenged.map(&:user_name).join(' and ')} to a match!", 'challenge'
      end

      def self.accept_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.accept!(challenger)
          SlackGamebot::Dispatch::Message.message_with_gif data.channel,  "#{challenge.challenged.map(&:user_name).join(' and ')} accepted #{challenge.challengers.map(&:user_name).join(' and ')} challenge.", 'game'
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to accept!'
        end
      end

      def self.decline_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.decline!(challenger)
          SlackGamebot::Dispatch::Message.message_with_gif data.channel,  "#{challenge.challenged.map(&:user_name).join(' and ')} declined #{challenge.challengers.map(&:user_name).join(' and ')} challenge.", 'no'
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to decline!'
        end
      end

      def self.cancel_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.cancel!(challenger)
          SlackGamebot::Dispatch::Message.message_with_gif data.channel,  "#{challenge.challengers.map(&:user_name).join(' and ')} canceled a challenge against #{challenge.challenged.map(&:user_name).join(' and ')}.", 'chicken'
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to cancel!'
        end
      end

      def self.lose_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.lose!(challenger)
          SlackGamebot::Dispatch::Message.message_with_gif data.channel, "Match has been recorded! #{challenge.match}.", 'loser'
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to lose!'
        end
      end

      def self.register_user(data)
        ts = Time.now.utc
        user = User.find_create_or_update_by_slack_id!(data.user)
        message = if user.created_at >= ts
                    "Welcome <@#{data.user}>! You're ready to play."
                  elsif user.updated_at >= ts
                    "Welcome back <@#{data.user}>, I've updated your registration."
                  else
                    "Welcome back <@#{data.user}>, you're already registered."
        end
        SlackGamebot::Dispatch::Message.message_with_gif data.channel, message, 'welcome'
        user
      end

      def self.leaderboard(data, arguments)
        max = 3
        case arguments.first.downcase
        when 'infinity'
          max = nil
        else
          max = Integer(arguments.first)
        end if arguments.any?
        SlackGamebot::Dispatch::Message.message data.channel, User.leaderboard(max)
      end

      def self.parse_command(text)
        parts = text.gsub(/[^[:word:]<>@\s]/, '').split.reject(&:blank?) if text
        [parts.first, parts[1], parts[2..parts.length]] if parts
      end

      def self.message(channel, text)
        Slack.chat_postMessage(channel: channel, text: text)
      end

      def self.message_with_gif(channel, text, keywords)
        gif = Giphy.random(keywords)
        text = text + "\n" + gif.image_url.to_s if gif
        SlackGamebot::Dispatch::Message.message channel, text
      end
    end
  end
end
