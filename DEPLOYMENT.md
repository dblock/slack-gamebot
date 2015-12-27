## Use a Service

Before deploying, consider using a game bot service and not worrying about installation or maintenance.

### PlayPlay.io

[![Add to Slack](https://platform.slack-edge.com/img/add_to_slack@2x.png)](http://playplay.io)

## Deploy Your Own Slack-Gamebot

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/dblock/slack-gamebot)

### MongoDB

Deploy slack-gamebot to Heroku and add a MongoLab or Compose MongoDB provider.

### Environment

#### SLACK_API_TOKEN

If your bot servces one team, set SLACK_API_TOKEN from the Bot integration settings on Slack. The first time you start the service it will automatically create a team using this token.

```
heroku config:add SLACK_API_TOKEN=...
```

#### GAMEBOT_ALIASES

Optional names for this bot.

```
heroku config:add GAMEBOT_ALIASES=":pong: pp"
```

#### GIPHY_API_KEY

Slack-Gamebot replies with animated GIFs. While it's currently not necessary, uyou may need to set GIPHY_API_KEY in the future, see [github.com/Giphy/GiphyAPI](https://github.com/Giphy/GiphyAPI) for details.

#### Multi-Game Setup

If your bot is a service, like the one on [playplay.io](http://playplay.io), register an aplication with Slack on https://api.slack.com and note the Slack client ID and secret. Create a game (currently console only).

```
heroku run irb --app=...

Running `irb` attached to terminal... up, run.7593

irb(main):002:0> $LOAD_PATH.unshift('.')
=> [".", "/app/vendor/ruby-2.2.0/lib/ruby/site_ruby/2.2.0" ... ]

irb(main):001:0> require 'slack-gamebot'
=> true

irb(main):006:0* Game.create!(name: 'pong', client_id: 'slack client id', client_secret: 'slack client secret', botname: 'pongbot', aliases: ['pp', 'pong'])
=> #<Game _id: 55c8f7da276eaa0003000000, ...>
```

This will allow you to create a team via `POST /teams?game=pong&code=`, where the code is obtained via Slack OAuth workflow. You can make a website to onboard teams, see [playplay.io](https://github.com/playplayio/playplay.io) for an example.

#### Database Backups

MongoLab and MongoHQ ensure a system-level backup. You might find it handy to backup the data elsewhere occasionally. If you can run `rake db:heroku:backup[app]` locally as long as you can execute `heroku config --app=...` as well. This creates a `.tar.gz` file from a MongoDB database configured on the Heroku `app` application.
