require 'whacamole/config'
require 'whacamole/events'
require 'whacamole/heroku_wrapper'
require 'whacamole/stream'

module Whacamole

  @@config = {}

  def self.configure(app_name)
    @@config[app_name.to_s] ||= Config.new(app_name)
    yield @@config[app_name.to_s]
  end

  def self.monitor
    threads = []
    @@config.each do |app_name, config|
      threads << Thread.new do
        heroku = HerokuWrapper.new(app_name, config.api_token)

        while true
          stream_url = heroku.create_log_session
          Stream.new(stream_url, heroku, &config.event_handler).watch
        end
      end
    end
    threads.collect(&:join)
  end
end

