## Use a Service

Before deploying, consider using and sponsoring [a free game bot service](https://www.playplay.io) and not worrying about installation or maintenance.

### PlayPlay.io

[![Add to Slack](https://platform.slack-edge.com/img/add_to_slack@2x.png)](https://www.playplay.io)

## Deploy Your Own Slack-Gamebot

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/dblock/slack-gamebot)

### MongoDB

Deploy slack-gamebot to Heroku and add a MongoLab or Compose MongoDB provider. You can use both free and paid tiers.

### Environment

#### SLACK_API_TOKEN

If your bot servces one team, create a new bot integration on Slack and set `SLACK_API_TOKEN` from the bot integration settings on Slack. The first time you start the service it will automatically create a team using this token.

```
heroku config:add SLACK_API_TOKEN=...
```

#### GAMEBOT_ALIASES

Optional names for this bot.

```
heroku config:add GAMEBOT_ALIASES=":pong: pp"
```

Aliases can also be configured per-game. A default game will be created the first time the bot starts, you can update its aliases from a console.

```ruby
game = Game.first
game.aliases << 'pp'
game.save!
```

#### GIPHY_API_KEY

Slack-Gamebot replies with animated GIFs. While it's currently not necessary, you may need to set `GIPHY_API_KEY` in the future, see [github.com/Giphy/GiphyAPI](https://github.com/Giphy/GiphyAPI) for details.

#### API_URL

The root of your API location, used when displaying the API URL for teams when invoking `set api`.

#### STRIPE_API_KEY and STRIPE_API_PUBLISHABLE_KEY

The free service on [playplay.io](https://www.playplay.io) allows users to upgrade to a paid service and enable a number of premium features. The money is collected with Stripe, and requires two keys, a private key for creating subscriptions on the back-end, and a public key for tokenizing credit cards client-side.

#### Multi-Game Setup

If your bot is a service, like the one on [playplay.io](https://www.playplay.io), register an aplication with Slack on https://api.slack.com and note the Slack client ID and secret. Create a game (currently console only).

```
heroku run script/console --app=...

2.2.1> Game.create!(name: 'pong', client_id: 'slack client id', client_secret: 'slack client secret', botname: 'pongbot', aliases: ['pp', 'pong'])
=> #<Game _id: 55c8f7da276eaa0003000000, ...>
```

This will allow you to create a team via `POST /teams?game=pong&code=`, where the code is obtained via Slack OAuth workflow. You can make a website to onboard teams, see [playplay.io](https://github.com/playplayio/playplay.io) for an example. There's no authentication or authorization currently built-in.

#### Database Backups

MongoLab and MongoHQ ensure a system-level backup. You might find it handy to backup the data elsewhere occasionally. If you can run `rake db:heroku:backup[app]` locally as long as you can execute `heroku config --app=...` as well. This creates a `.tar.gz` file from a MongoDB database configured on the Heroku `app` application.
