## Use a Service

Before deploying, consider using a game bot service and not worrying about installation or maintenance.

### Ping-Pong with PlayPlay.io

[![Add to Slack](https://platform.slack-edge.com/img/add_to_slack@2x.png)](http://playplay.io)

## Deploy Your Own Slack-Gamebot

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/dblock/slack-gamebot)

For now, because of environment-based aliases, each deployment should focus on a single type of game, eg. ping-pong.

### MongoDB

Deploy slack-gamebot to Heroku and add a MongoLab or Compose MongoDB provider.

### Environment

#### SLACK_API_TOKEN

If your bot servces one team, set SLACK_API_TOKEN from the Bot integration settings on Slack. The first time you start the service it will automatically create a team using this token.

```
heroku config:add SLACK_API_TOKEN=...
```

#### GAMEBOT_SECRET

If your bot services one team, DM Slack-Gamebot using this secret to perform a season reset. Only tell GameBot captains.

```
heroku config:add GAMEBOT_SECRET=...
```

#### GAMEBOT_ALIASES

Optional names for this bot.

```
heroku config:add GAMEBOT_ALIASES=":pong: pp"
```

#### GIPHY_API_KEY

Slack-Gamebot replies with animated GIFs. While it's currently not necessary, uyou may need to set GIPHY_API_KEY in the future, see [github.com/Giphy/GiphyAPI](https://github.com/Giphy/GiphyAPI) for details.

#### SLACK_CLIENT_ID and SLACK_CLIENT_SECRET

If your bot is a service, like the one on [playplay.io](http://playplay.io), register an aplication with Slack on https://api.slack.com and set `SLACK_CLIENT_ID` and `SLACK_CLIENT_SECRET`. This will allow you to create a team via `POST /teams?code=`, where the code is obtained via Slack OAuth workflow. You can make a website to onboard teams, see [playplay.io](https://github.com/playplayio/playplay.io) for an example.
