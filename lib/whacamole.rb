require 'whacamole/config'
require 'whacamole/events'
require 'whacamole/heroku_wrapper'
require 'whacamole/stream'

module Whacamole
  extend self

  @config = {}

  def configure(app_name)
    @config[app_name.to_s] ||= Config.new(app_name)
    yield @config[app_name.to_s]
  end

  def monitor
    threads = []
    @config.each do |app_name, config|
      threads << Thread.new do
        heroku = HerokuWrapper.new(app_name, config.api_token, config.dynos, config.restart_window)

        while true
          stream_url = heroku.create_log_session
          Stream.new(stream_url, heroku, config.restart_threshold, &config.event_handler).watch
        end
      end
    end
    threads.collect(&:join)
  end
end
