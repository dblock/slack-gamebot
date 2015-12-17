## Deploy Slack-Gamebot

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/dblock/slack-gamebot)

### MongoDB

Deploy slack-gamebot to Heroku and add a MongoLab or Compose MongoDB provider. You can use their free tiers.

### Environment

#### SLACK_API_TOKEN

Set SLACK_API_TOKEN from the Bot integration settings on Slack.

```
heroku config:add SLACK_API_TOKEN=...
```

#### GAMEBOT_SECRET

DM Slack-Gamebot using this secret to perform a season reset. Only tell GameBot admins.

```
heroku config:add GAMEBOT_SECRET=...
```

#### SLACK_RUBY_BOT_ALIASES

Optional names for this bot.

```
heroku config:add SLACK_RUBY_BOT_ALIASES=":pong: pp"
```

#### GIPHY_API_KEY

Slack-Gamebot replies with animated GIFs. While it's currently not necessary, uyou may need to set GIPHY_API_KEY in the future, see [github.com/Giphy/GiphyAPI](https://github.com/Giphy/GiphyAPI) for details.

### Heroku Idling

Heroku free tier applications will idle. Use [Kaffeine](https://kaffeine.herokuapp.com/#!) or similar to prevent your instance from sleeping or pay for a production dyno.


