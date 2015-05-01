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
        else
          SlackGamebot::Dispatch::Message.message data.channel, "Sorry <@#{data.user}>, I don't understand that command!"
        end if bot_name == SlackGamebot.config.user
      rescue Mongoid::Errors::Validations => e
        raise ArgumentError, e.document.errors.first[1]
      end

      private

      def self.challenge(data, _command, arguments)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.create_from_teammates_and_opponents!(challenger, arguments)
        SlackGamebot::Dispatch::Message.message data.channel, "#{challenge.challengers.map(&:user_name).join(' and ')} challenged #{challenge.challenged.map(&:user_name).join(' and ')} to a match!"
      end

      def self.accept_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.accept!(challenger)
          SlackGamebot::Dispatch::Message.message data.channel,  "#{challenge.challenged.map(&:user_name).join(' and ')} accepted #{challenge.challengers.map(&:user_name).join(' and ')} challenge."
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to accept!'
        end
      end

      def self.decline_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.decline!(challenger)
          SlackGamebot::Dispatch::Message.message data.channel,  "#{challenge.challenged.map(&:user_name).join(' and ')} declined #{challenge.challengers.map(&:user_name).join(' and ')} challenge."
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to decline!'
        end
      end

      def self.cancel_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.cancel!(challenger)
          SlackGamebot::Dispatch::Message.message data.channel,  "#{challenge.challengers.map(&:user_name).join(' and ')} canceled a challenge against #{challenge.challenged.map(&:user_name).join(' and ')}."
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to cancel!'
        end
      end

      def self.lose_challenge(data)
        challenger = User.find_create_or_update_by_slack_id!(data.user)
        challenge = Challenge.find_by_user(challenger)
        if challenge
          challenge.lose!(challenger)
          SlackGamebot::Dispatch::Message.message data.channel, "Match has been recorded! #{challenge.match}."
        else
          SlackGamebot::Dispatch::Message.message data.channel, 'No challenge to lose!'
        end
      end

      def self.register_user(data)
        ts = Time.now.utc
        user = User.find_create_or_update_by_slack_id!(data.user)
        if user.created_at >= ts
          SlackGamebot::Dispatch::Message.message data.channel, "Welcome <@#{data.user}>! You're ready to play."
        elsif user.updated_at >= ts
          SlackGamebot::Dispatch::Message.message data.channel, "Welcome back <@#{data.user}>, I've updated your registration."
        else
          SlackGamebot::Dispatch::Message.message data.channel, "Welcome back <@#{data.user}>, you're already registered."
        end
        user
      end

      def self.parse_command(text)
        parts = text.gsub(/[^[:word:]<>@\s]/, '').split.reject(&:blank?) if text
        bot_name = parts.first if parts
        [bot_name, parts[1], parts[2..parts.length]]
      end

      def self.message(channel, text)
        Slack.chat_postMessage(channel: channel, text: text)
      end
    end
  end
end
