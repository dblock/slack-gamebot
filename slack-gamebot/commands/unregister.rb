module SlackGamebot
  module Commands
    class Unregister < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Premium

      premium_command 'unregister' do |client, data, match|
        if !match['expression'] || match['expression'] == 'me'
          user = ::User.find_create_or_update_by_slack_id!(client, data.user)
          user.unregister!
          client.say(channel: data.channel, text: "I've removed #{user.slack_mention} from the leaderboard.", gif: 'removed')
          logger.info "UNREGISTER ME: #{client.owner} - #{user.slack_mention}"
        elsif match['expression']
          user = ::User.find_create_or_update_by_slack_id!(client, data.user)
          names = match['expression'].split.reject(&:blank?)
          if !user.captain?
            client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
            logger.info "UNREGISTER: #{client.owner} - #{names.and}, failed, not captain"
          else
            users = names.map { |name| ::User.find_by_slack_mention!(client.owner, name) }
            users.each(&:unregister!)
            slack_mentions = users.map(&:slack_mention)
            client.say(channel: data.channel, text: "I've removed #{slack_mentions.and} from the leaderboard.", gif: 'find')
            logger.info "UNREGISTER: #{client.owner} - #{names.and}"
          end
        end
      end
    end
  end
end
