## Debugging

### Locally

You can debug your instance of slack-gamebot with a built-in console.

```
$ ./script/console

2.3.1 :001 > Game.map(&:name)
=> ['pong', 'pool']
```

### Silence Mongoid Logger

If Mongoid logging is annoying you.

```ruby
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO
```

### Heroku

```
heroku run script/console --app=...

Running `script/console` attached to terminal... up, run.7593

2.2.1 > Game.count
=> 3

2.2.1 > Game.last
=> #<Game _id: 55c8f7da276eaa0003000000, ...>
```

### Dokku

```
$ gem install dokku-cli

$ git remote add dokku dokku@dblock-plum.digitalocean.playplay.io:game-bot

$ dokku run script/console
Running ssh -t -p 22 dokku@dblock-plum.digitalocean.playplay.io run game-bot script/console...

irb(main):001:0> Team.count
=> 668
```
