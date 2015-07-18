Slack-Gamebot
=============

[![Build Status](https://travis-ci.org/dblock/slack-gamebot.png)](https://travis-ci.org/dblock/slack-gamebot)

A generic game bot for slack. Works for ping-pong (2, 4 or more players), chess, etc.

![](screenshots/game.gif)

## Installation

Create a new Bot Integration under [services/new/bot](http://slack.com/services/new/bot). Note the API token.
You will be able to invoke gamebot by the name you give it in the UI above.

Run `SLACK_API_TOKEN=<your API token> GAMEBOT_SECRET=secret foreman start`

## Production Deployment

See [DEPLOYMENT](DEPLOYMENT.md)

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

![](screenshots/register.gif)

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

#### gamebot challenges

Displays all outstanding (proposed and accepted) challenges.

#### gamebot rank [<user>, ...]

Show the smallest range of ranks for a list of players.  If no user is specified, your rank is shown.

```
gamebot rank @WangHoe @DengYaping

2. Deng Yaping: 1 win, 3 losses (elo: 24)
3. Wang Hoe: 0 wins, 1 loss (elo: -12)
```

#### gamebot reset [secret]

Direct-message gamebot to reset all users and pending challenges.

```
gamebot reset <secret>

Welcome to the new season!
```

#### gamebot season

Display current seasons.

```
gamebot season

Current: william: 1 win, 0 losses (elo: 48), 1 game, 2 players
```

#### gamebot seasons

Display current and past seasons.

```
gamebot seasons

Current: william: 1 win, 0 losses (elo: 48), 1 game, 2 players
2015-07-16: dblock: 28 wins, 19 losses (elo: 214), 206 games, 25 players
```

## API

Slack-gamebot implements a Hypermedia API. Navigate to the application root to browse through available objects and methods. Artsy's Gamebot is [here](http://artsy-ping-pong-gamebot.herokuapp.com), you can see [dblock's current elo](http://artsy-ping-pong-gamebot.herokuapp.com/users/5543f64d6237640003000000).

![](screenshots/api.png)

We recommend [HyperClient](https://github.com/codegram/hyperclient) to query the API programmatically in Ruby.

## Contributing

This bot is built with [slack-ruby-bot](https://github.com/dblock/slack-ruby-bot). See [CONTRIBUTING](CONTRIBUTING.md).

## Copyright and License

Copyright (c) 2015, Daniel Doubrovkine, Artsy and [Contributors](CHANGELOG.md).

This project is licensed under the [MIT License](LICENSE.md).
