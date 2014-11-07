whacamole
=========

[![Build Status](https://travis-ci.org/arches/whacamole.png)](https://travis-ci.org/arches/whacamole)

Whacamole keeps track of your Heroku dynos' memory usage and restarts large dynos before they start
swapping to disk (aka get super slow).

Here’s what Heroku says about dyno memory usage:

> Dynos are available in a few different sizes. The maximum amount of RAM available to your application depends on the dyno size you use.
>
> Dynos whose processes exceed their memory quota are identified by an R14 error in the logs. This doesn’t terminate the process, but it does warn of deteriorating application conditions: memory used above quota will swap out to disk, which substantially degrades dyno performance.
> 
> If the memory size of your dyno keeps growing until it reaches five times its quota (for a 1X dyno, 512MB x 5 = 2.5GB), the dyno manager will restart your dyno with an R15 error.
>
> - From https://devcenter.heroku.com/articles/dynos on 3/12/14

Heroku dynos swap to disk for up to 5GB (2X dynos) or up to THIRTY GIGABYTES (PX dynos). That is not good and that is the problem whacamole addresses.

# Usage

Enable log-runtime-metrics on your heroku app:

```bash
$ heroku labs:enable log-runtime-metrics --app YOUR_APP_NAME
```

Add whacamole to your gemfile:

```ruby
gem 'whacamole'
```

Create a config file with your app info. Personally I put it in my Rails app at config/whacamole.rb. The
most important parts are your app name and your Heroku api token (which can be found by running `heroku auth:token`
on the command line).

```ruby
Whacamole.configure("HEROKU APP NAME") do |config|
  config.api_token = ENV['HEROKU_API_TOKEN'] # you could also paste your token in here as a string
end

# you can monitor multiple apps at once, just add more configure blocks
Whacamole.configure("ANOTHER HEROKU APP") do |config|
  config.api_token = ENV['HEROKU_API_TOKEN'] # you could also paste your token in here as a string
end

# you can specify which dynos to watch for each app (default: `web`):
Whacamole.configure("HEROKU APP WITH MULTIPLE DYNO TYPES") do |config|
  config.api_token = ENV['HEROKU_API_TOKEN'] # you could also paste your token in here as a string
  config.dynos = %w{web worker}
  config.restart_threshold = 500 # in megabytes. default is 1000 (good for 2X dynos)
end
```

Add whacamole to your Procfile, specifying the config file you created:

```ruby
whacamole: bundle exec whacamole -c ./config/whacamole.rb
```

Start foreman, and you're done!

```bash
# locally
$ foreman start whacamole

# on heroku
$ heroku ps:scale whacamole=1 --app YOUR_APP_NAME
```

# Events

Each ping and restart is available to you, for example in case you want to see with your own eyes that it's working.

Methods on DynoSize events
 * event.process (the heroku process, eg "web.1")
 * event.size (dyno size, eg 444.06)
 * event.units (units for the size, eg "MB")

Methods on DynoRestart events
  * event.process (the heroku process, eg "web.1")
  
To access the events, add a handler in your config. Event handlers take a single argument, the event. This handler will log the event in your Heroku logs:

```ruby
Whacamole.configure("HEROKU APP NAME") do |config|
  config.event_handler = lambda do |e|
    puts e.inspect.to_s
  end
end
```

## Self Promotion

If you like Whacamole, help spread the word! Tell your friends, or at the very least star the repo on github.

For more heroku goodness, check out http://github.com/arches/table_print and http://github.com/arches/marco-polo
