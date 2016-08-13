module SlackGamebot
  module Commands
    class Help < SlackRubyBot::Commands::Base
      HELP = <<-EOS
I am your friendly Gamebot, here to help.

```
General
-------
hi: be nice, say hi to your bot
team: show your team's info and captains
register: register yourself as a player
unregister: unregister yourself
help: get this helpful message
sucks: express some frustration

Games
-----
challenge <opponent>, ... [with <teammate>, ...]: challenge opponent(s) to a game
accept: accept a challenge
decline: decline a previous challenge
cancel: cancel a previous challenge
lost [to <opponent>] [score, ...]: record your loss
resigned [to <opponent>]: record a resignation
draw: record a tie

Stats
-----
leaderboard [number|infinity]: show the leaderboard, eg. leaderboard 10
rank [<player> ...]: rank a player or a list of players
matches [number|infinity]: show this season's matches
season: show current season

Captains
--------
promote <player>: promote a user to captain
demote me: demote you from captain
set nickname <player> [name], unset nickname <player>: set/unset someone's nickname

Premium
-------
seasons: show all seasons
reset <team>: reset all stats, start a new season
unregister <player>: remove a player from the leaderboard
set nickname [name], unset nickname: set/unset your nickname displayed in leaderboards
set gifs [on|off]: enable/disable animated GIFs, default is on
set aliases [<alias> ...], unset aliases: set/unset additional bot aliases
set elo [number]: set base elo for the team
set api [on|off]: enable/disable team data in the public API, default is off
set unbalanced [on|off]: allow matches between different numbers of players, default is off
```
        EOS
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: [
          HELP,
          SlackGamebot::INFO,
          client.owner.reload.premium? ? nil : client.owner.upgrade_text
        ].compact.join("\n"))
        client.say(channel: data.channel, gif: 'help')
        logger.info "HELP: #{client.owner} - #{data.user}"
      end
    end
  end
end
