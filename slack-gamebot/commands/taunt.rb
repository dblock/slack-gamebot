module SlackGamebot
  module Commands
    class Taunt < SlackRubyBot::Commands::Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'taunt' do |client, data, match|
        taunter = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'] ? match['expression'].split.reject(&:blank?) : []
        if arguments.empty?
          client.say(channel: data.channel, text: 'Please provide a user name to taunt. (╯°□°）╯︵ ┻━┻')
        else
          victim = ::User.find_many_by_slack_mention!(client, arguments)
          taunts = Array.new
          taunts << "#{victim.map(&:user_name).and} #{victim.count == 1 ? 'is' : 'are'} way much worser at :table_tennis_paddle_and_ball: than a baby Derek!"
          taunts << "#{victim.map(&:user_name).and} #{victim.count == 1 ? 'is' : 'are'} way much worser at :table_tennis_paddle_and_ball: than a baby moose!"
          taunts << "#{victim.map(&:user_name).and} #{victim.count == 1 ? 'plays' : 'play'} like a red panda. Cute and fuzzy. "
          taunts << "#{victim.map(&:user_name).and} - Sometimes you win, sometimes you lose, and sometimes it rains. Prepare for thunder. "
	        n = rand(taunts.length)
          taunt = taunts[n]  
          client.say(channel: data.channel, text: "#{taunter.user_name} says #{taunt}")
          logger.info "TAUNT: #{client.owner} - #{taunter.user_name}"
        end
      end
    end
  end
end
