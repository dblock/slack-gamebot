## Debugging

You can debug your instance of slack-gamebot with Ruby. For example, on Heroku:

```
heroku run irb --app=...

Running `irb` attached to terminal... up, run.7593

irb(main):002:0> $LOAD_PATH.unshift('.')
=> [".", "/app/vendor/ruby-2.2.0/lib/ruby/site_ruby/2.2.0" ... ]

irb(main):001:0> require 'slack-gamebot'
=> true

irb(main):006:0* Challenge.last
=> #<Challenge _id: 55c8f7da276eaa0003000000, ...>

irb(main):006:0* jordana = User.find_by_slack_mention!('jordana')
=> #<User _id: 5547c7586166340003000000,  ...>
```
