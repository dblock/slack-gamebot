## Development Environment

You may want to watch [Your First Slack Bot Service video](http://code.dblock.org/2016/03/11/your-first-slack-bot-service-video.html) first.

### Prerequisites

Ensure that you can build the project and run tests. You will need these.

- [MongoDB](https://docs.mongodb.com/manual/installation/)
- [Firefox](https://www.mozilla.org/firefox/new/)
- [Geckodriver](https://github.com/mozilla/geckodriver), download, `tar vfxz` and move to `/usr/local/bin`
- Ruby 2.3.1

```
bundle install
bundle exec rake
```

### Slack Team

Create a Slack team [here](https://slack.com/create).

### Slack App

Create a test app [here](https://api.slack.com/apps). This gives you a client ID and a client secret.

Under _Features/OAuth & Permissions_, configure the redirect URL to `http://localhost:5000?game=pong`.

Add the following Permission Scope.

* Add a bot user with the username @bot.

### Run a Console

Create a game from the console.

```
$ script/console

2.3.1> Game.create!(name: 'pong', client_id: 'slack client id', client_secret: 'slack client secret', bot_name: 'pongbot', aliases: ['pp', 'pong'])
```

### Stripe Keys

If you want to test subscriptions and payment-related functions you need a [Stripe](https://www.stripe.com) account and test keys. Create a `.env` file.

```
STRIPE_API_PUBLISHABLE_KEY=pk_test_key
STRIPE_API_KEY=sk_test_key
```

### Start the Bot

```
$ foreman start

08:54:07 web.1  | started with pid 32503
08:54:08 web.1  | I, [2017-08-04T08:54:08.138999 #32503]  INFO -- : listening on addr=0.0.0.0:5000 fd=11
```

Navigate to [localhost:5000](http://localhost:5000). Don't add to Slack from that page, the links contain the hardcoded Playplay.io IDs.






