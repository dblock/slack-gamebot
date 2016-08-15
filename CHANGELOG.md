### Changelog

* [#113](https://github.com/dblock/slack-gamebot/issues/113): Store elo history - [@dblock](https://github.com/dblock).
* [#129](https://github.com/dblock/slack-gamebot/issues/129): Added longest winning and losing streaks in leaderboard - [@dblock](https://github.com/dblock).
* [#124](https://github.com/dblock/slack-gamebot/issues/124): Allow unbalanced challenges via `set unbalanced on` - [@dblock](https://github.com/dblock).
* [#130](https://github.com/dblock/slack-gamebot/issues/130): Added `unset` to unset settings - [@dblock](https://github.com/dblock).
* [#123](https://github.com/dblock/slack-gamebot/issues/123): Captains can set other user's nicknames - [@dblock](https://github.com/dblock).
* [#88](https://github.com/dblock/slack-gamebot/issues/88): Set `nickname` to obfuscate your username in leaderboard output - [@dblock](https://github.com/dblock).
* [#86](https://github.com/dblock/slack-gamebot/issues/86): Added `unregister` to remove yourself or another player from the leaderboard - [@dblock](https://github.com/dblock).
* [#119](https://github.com/dblock/slack-gamebot/issues/119): Fix: teams reporting matches with `lost to` incorrectly marked as dead - [@dblock](https://github.com/dblock).
* [#114](https://github.com/dblock/slack-gamebot/issues/114): Set a team base elo rating with `set elo` for new seasons - [@dblock](https://github.com/dblock).
* [#116](https://github.com/dblock/slack-gamebot/issues/116): Notify that a team has been upgraded in Slack - [@dblock](https://github.com/dblock).
* [#117](https://github.com/dblock/slack-gamebot/issues/117): Send a welcome message when the bot joins a channel - [@dblock](https://github.com/dblock).
* [#112](https://github.com/dblock/slack-gamebot/issues/112): Fix: matches recorded with `lost to` are not displayed in `matches` - [@dblock](https://github.com/dblock).
* [#118](https://github.com/dblock/slack-gamebot/issues/118): Fix: aliases - [@dblock](https://github.com/dblock).
* Features such as `seasons` and `set` now require a premium subscription - [@dblock](https://github.com/dblock).
* Merged playplay.io website, support SSL - [@dblock](https://github.com/dblock).
* [#103](https://github.com/dblock/slack-gamebot/issues/103): The `set api` method will display team API URL when on - [@dblock](https://github.com/dblock).
* [#105](https://github.com/dblock/slack-gamebot/issues/105): Fix: `rank` displays multiple unranked users - [@dblock](https://github.com/dblock).
* [#104](https://github.com/dblock/slack-gamebot/issues/104): Fix: `rank` leaks users from other teams - [@dblock](https://github.com/dblock).
* [#102](https://github.com/dblock/slack-gamebot/issues/102), [#101](https://github.com/dblock/slack-gamebot/issues/101): Unable to set options with existing challenges - [@dblock](https://github.com/dblock).
* [#100](https://github.com/dblock/slack-gamebot/issues/100): Error re-registering and de-activating a team multiple times - [@dblock](https://github.com/dblock).
* [#98](https://github.com/dblock/slack-gamebot/issues/98): Reactivating a team doesn't update auth token - [@dblock](https://github.com/dblock).
* [#97](https://github.com/dblock/slack-gamebot/pull/97): Reverse leaderboard by specifying a negative number - [@ashkan18](https://github.com/ashkan18), [@dblock](https://github.com/dblock).
* [#94](https://github.com/dblock/slack-gamebot/issues/94): De-registering and re-registering a team just reactivates the old team - [@dblock](https://github.com/dblock).
* [#92](https://github.com/dblock/slack-gamebot/issues/92): Leaderboard without ranked players now says that there're no ranked players - [@dblock](https://github.com/dblock).
* [#80](https://github.com/dblock/slack-gamebot/issues/80): Empty season produces `undefined method 'map' for nil:NilClass` error - [@dblock](https://github.com/dblock).
* [#79](https://github.com/dblock/slack-gamebot/issues/79): Fixed order of scores in messages, winners first - [@dblock](https://github.com/dblock).
* [#78](https://github.com/dblock/slack-gamebot/issues/78): Losers can record a loss or a resignation without a prior challenge - [@dblock](https://github.com/dblock).
* [#77](https://github.com/dblock/slack-gamebot/issues/77): Opt-in now required to expose team data via the public API - [@dblock](https://github.com/dblock).
* [#76](https://github.com/dblock/slack-gamebot/issues/76): Prevent multiple bots from responding to you suck - [@dblock](https://github.com/dblock).
* [#75](https://github.com/dblock/slack-gamebot/issues/75): Nudge inactive teams every couple of weeks - [@dblock](https://github.com/dblock).
* [#74](https://github.com/dblock/slack-gamebot/issues/74): Seasons may have multiple winners with the same elo, wins, losses and ties - [@dblock](https://github.com/dblock).
* [#73](https://github.com/dblock/slack-gamebot/issues/73): Handled errors are no longer logged as fatal exceptions - [@dblock](https://github.com/dblock).
* [#32](https://github.com/dblock/slack-gamebot/issues/32): Players can express their frustration with `suck` - [@dblock](https://github.com/dblock).
* [#26](https://github.com/dblock/slack-gamebot/issues/26): Players can `resign` a challenge - [@dblock](https://github.com/dblock).
* [#65](https://github.com/dblock/slack-gamebot/issues/65): Captains can set per-team bot aliases with `set aliases <alias|none> ...` - [@dblock](https://github.com/dblock).
* [#57](https://github.com/dblock/slack-gamebot/issues/57): Captains can turn team GIFs on/off with `set gifs on|off` - [@dblock](https://github.com/dblock).
* [#70](https://github.com/dblock/slack-gamebot/issues/70): Players can limit `matches <number|infinity>` - [@dblock](https://github.com/dblock).
* [#71](https://github.com/dblock/slack-gamebot/issues/71): Scores can be separated by dashes and commas - [@dblock](https://github.com/dblock).
* [#67](https://github.com/dblock/slack-gamebot/issues/67): Captains can reset seasons with both team ID and name - [@dblock](https://github.com/dblock).
* [#68](https://github.com/dblock/slack-gamebot/issues/68): Fix: `matches` was displaying matches from other teams - [@dblock](https://github.com/dblock).
* [#69](https://github.com/dblock/slack-gamebot/issues/69): Players can `draw` a game and score ties - [@dblock](https://github.com/dblock).
* [#58](https://github.com/dblock/slack-gamebot/issues/58): Automatically purge teams inactive for two weeks - [@dblock](https://github.com/dblock).
* [#66](https://github.com/dblock/slack-gamebot/issues/66): Added `script/console` - [@dblock](https://github.com/dblock).
* [#64](https://github.com/dblock/slack-gamebot/issues/64): Rewrite links in the Hypermedia API root to make them clickable - [@dblock](https://github.com/dblock).
* [#62](https://github.com/dblock/slack-gamebot/issues/62): Fix: NewRelic: NoMethodError: private method 'params' called for Grape::Endpoint - [@dblock](https://github.com/dblock).
* [#61](https://github.com/dblock/slack-gamebot/issues/61): Added `rake db:heroku:backup[app]` - [@dblock](https://github.com/dblock).
* [#60](https://github.com/dblock/slack-gamebot/issues/60): Added NewRelic instrumentation - [@dblock](https://github.com/dblock).
* [#59](https://github.com/dblock/slack-gamebot/issues/59): Ensure MongoDB indexes on start - [@dblock](https://github.com/dblock).
* [#56](https://github.com/dblock/slack-gamebot/issues/56): Support multiple games per instance - [@dblock](https://github.com/dblock).
* [#53](https://github.com/dblock/slack-gamebot/issues/53): Expanded help with complete command details - [@dblock](https://github.com/dblock).
* [#51](https://github.com/dblock/slack-gamebot/issues/51): Automatically restart bot when Slack closes a connection - [@dblock](https://github.com/dblock).
* [#52](https://github.com/dblock/slack-gamebot/issues/52): Added an API `/status` endpoint that pings the first team - [@dblock](https://github.com/dblock).
* [#50](https://github.com/dblock/slack-gamebot/issues/50): Automatically disable teams with `account_inactive` - [@dblock](https://github.com/dblock).
* [#25](https://github.com/dblock/slack-gamebot/issues/25): Players can `draw` a challenge, all players have to `draw` - [@dblock](https://github.com/dblock).
* [#46](https://github.com/dblock/slack-gamebot/issues/46): Captains can `reset` seasons - [@dblock](https://github.com/dblock).
* [#46](https://github.com/dblock/slack-gamebot/issues/46): Captains can `promote` and `demote` - [@dblock](https://github.com/dblock).
* [#46](https://github.com/dblock/slack-gamebot/issues/46): Players can see `team` information - [@dblock](https://github.com/dblock).
* [#49](https://github.com/dblock/slack-gamebot/issues/49): Disallow indexing by serving a robots.txt - [@dblock](https://github.com/dblock).
* [#48](https://github.com/dblock/slack-gamebot/issues/48): API failures return 400 status code with a hypermedia response - [@dblock](https://github.com/dblock).
* [#45](https://github.com/dblock/slack-gamebot/pull/45): Added support for multiple teams, rolled out [playplay.io](http://playplay.io) - [@dblock](https://github.com/dblock).
* [#40](https://github.com/dblock/slack-gamebot/issues/40): You can disable GIFs via `ENV['SLACK_RUBY_BOT_SET_GIFS']` - [@dblock](https://github.com/dblock).
* [#38](https://github.com/dblock/slack-gamebot/issues/38): Fix: SystemStackError: stack level too deep w/ MongoLab - [@dblock](https://github.com/dblock).
* [#35](https://github.com/dblock/slack-gamebot/issues/35): Fix: missing ranking and broken leaderboard in first game after reset - [@dblock](https://github.com/dblock).
* [#34](https://github.com/dblock/slack-gamebot/issues/34): Fix: `season` incorrectly reports no seasons after reset - [@dblock](https://github.com/dblock).
* Fix: correctly handle `user_change` event - [@dblock](https://github.com/dblock).
* [#29](https://github.com/dblock/slack-gamebot/issues/29): Fix: `season` incorrectly reports number of players - [@dblock](https://github.com/dblock).
* [#24](https://github.com/dblock/slack-gamebot/issues/24): Players can record game scores with `lost <scores>` - [@dblock](https://github.com/dblock).
* [#20](https://github.com/dblock/slack-gamebot/issues/20): Added support for matches - [@dblock](https://github.com/dblock).
* Fix: ignore unplayed challenges during current season in `gamebot season` - [@dblock](https://github.com/dblock).
* [#4](https://github.com/dblock/slack-gamebot/issues/4): Added support for seasons - [@dblock](https://github.com/dblock).
* [#17](https://github.com/dblock/slack-gamebot/pull/17): Players can see a rank section for N players with `rank <player> ...` - [@wrgoldstein](https://github.com/wrgoldstein).
* Initial public release - [@dblock](https://github.com/dblock).
