## Deploy Slack-Gamebot

Each deployment focuses on a single type of game, eg. ping-pong.

### MongoDB

Deploy slack-gamebot to Heroku and add a MongoLab or Compose MongoDB provider.

#### SLACK_RUBY_BOT_ALIASES

Optional names for this bot.

```
heroku config:add SLACK_RUBY_BOT_ALIASES=":pong: pp"
```

#### GIPHY_API_KEY

Slack-Gamebot replies with animated GIFs. While it's currently not necessary, uyou may need to set GIPHY_API_KEY in the future, see [github.com/Giphy/GiphyAPI](https://github.com/Giphy/GiphyAPI) for details.
