Slack-Gamebot
=============

[![Build Status](https://travis-ci.org/dblock/slack-gamebot.png)](https://travis-ci.org/dblock/slack-gamebot)

A game bot for slack.

## Installation

Create a new Bot Integration under [services/new/bot](http://slack.com/services/new/bot). Note the API token.
You will be able to invoke gamebot by the name you give it in the UI above.

Deploy this application to Heroku or another service. Set _SLACK_API_TOKEN_.

```
heroku config:add SLACK_API_TOKEN=...
```

## Usage

Start talking to your bot!

![](screenshots/hi.png)

### Commands

#### gamebot

Shows GameBot version and links.

#### gamebot hi

Politely says 'hi' back.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md).

## Copyright and License

Copyright (c) 2015, Daniel Doubrovkine, Artsy and [Contributors](CHANGELOG.md).

This project is licensed under the [MIT License](LICENSE.md).
