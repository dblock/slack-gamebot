module SlackGamebot
  module Commands
    class Help < SlackRubyBot::Commands::Base
      HELP = <<-EOS
I am your friendly GameBot, here to help.

```
General
-------
hi: be nice, say hi to your bot
team: show your team's info and captains
register: register yourself as a player
help: get this helpful message

Games
-----
challenge <opponent>, ... [with <teammate>, ...]: challenge opponent(s) to a game
accept: accept a challenge
lost [score, ...]: record your loss
draw: record a tie
decline: decline a challenge
cancel: cancel a challenge

Stats
-----
leaderboard [number|infinity]: show the leaderboard, eg. leaderboard 10
rank [<player> ...]: rank a player or a list of players
seasons: show all seasons
season: show current season

Captains
--------
reset <team>: reset all stats, start a new season
promote <player>: promote a user to captain
demote me: demote you from captain
```
Powered by the open-source https://github.com/dblock/slack-gamebot.
Follow us on https://twitter.com/playplayio.
        EOS
      def self.call(client, data, _match)
        send_message_with_gif client, data.channel, HELP, 'help'
        logger.info "HELP: #{client.team} - #{data.user}"
      end
    end
  end
end
