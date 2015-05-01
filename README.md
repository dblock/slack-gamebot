Slack-Gamebot
=============

[![Build Status](https://travis-ci.org/dblock/slack-gamebot.png)](https://travis-ci.org/dblock/slack-gamebot)

A generic game bot for slack. Works for ping-pong (2, 4 or more players), chess, etc.

## Installation

Create a new Bot Integration under [services/new/bot](http://slack.com/services/new/bot). Note the API token.
You will be able to invoke gamebot by the name you give it in the UI above.

Deploy this application to Heroku with MongoLab or Compose or another similar service. Set _SLACK_API_TOKEN_.

```
heroku config:add SLACK_API_TOKEN=...
```

While it's currently not necessary, uyou may need to set _GIPHY_API_KEY_ in the future, see [github.com/Giphy/GiphyAPI](https://github.com/Giphy/GiphyAPI) for details.

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

## Usage

Start talking to your bot!

![](screenshots/hi.png)

### Commands

#### gamebot

Shows GameBot version and links.

#### gamebot hi

Politely says 'hi' back.

#### gamebot help

Get help.

#### gamebot register

Registers a user.

```
gamebot register

Welcome Victor Barna! You're ready to play.
```

This command can also update a user's registration, for example after the user has been renamed. The bot notices user renames, but this may be necessary if the bot wasn't running during that operation.

```
gamebot register

Welcome back Victor Barna! I've updated your registration.
```

#### gamebot challenge <opponent>, ... [with <teammate>, ...]

Creates a new challenge between you and an opponent.

```
gamebot challenge @WangHoe

Victor Barna challenged Wang Hoe to a match!
```

You can create group challenges, too. Both sides must have the same number of players.

```
gamebot challenge @WangHoe @ZhangJike with @DengYaping

Victor Barna and Deng Yaping challenged Wang Hoe and Zhang Jike to a match!
```

#### gamebot accept

Accept a challenge.

```
gamebot accept

Wang Hoe and Zhang Jike accepted Victor Barna and Deng Yaping's challenge.
```

#### gamebot decline

Decline a challenge.

```
gamebot decline

Wang Hoe and Zhang Jike declined Victor Barna and Deng Yaping's challenge.
```

#### gamebot cancel

Cancel a challenge.

```
gamebot cancel

Victor Barna and Deng Yaping canceled a challenge against Wang Hoe and Zhang Jike.
```

#### gamebot leaderboard [number|infinity]

Get the leaderboard.

```
gamebot leaderboard

1. Victor Barna: 3 wins, 2 losses (elo: 148)
2. Deng Yaping: 1 win, 3 losses (elo: 24)
3. Wang Hoe: 0 wins, 1 loss (elo: -12)
```

The leaderboard contains 3 topmost players ranked by [Elo](http://en.wikipedia.org/wiki/Elo_rating_system), use _leaderboard 10_ or _leaderboard infinity_ to see 10 players or more, respectively.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md).

## Copyright and License

Copyright (c) 2015, Daniel Doubrovkine, Artsy and [Contributors](CHANGELOG.md).

This project is licensed under the [MIT License](LICENSE.md).
