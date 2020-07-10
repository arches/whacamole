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
    @config.map { |app_name, config| build_monitor_thread app_name, config }
           .map(&:join)
    puts 'Monitor threads all terminated'
  end

  private

  def build_monitor_thread(app_name, config)
    Thread.new do
      puts 'New monitor thread started'
      heroku = HerokuWrapper.new(app_name, config.api_token, config.dynos, config.restart_window)

      while true
        begin
          puts 'Creating new Heroku log session'
          stream_url = heroku.create_log_session
          puts 'Starting new log stream'
          Stream.new(stream_url, heroku, config.restart_threshold, &config.event_handler).watch
        rescue Whacamole::Stream::StreamFailure
          puts 'Heroku log stream sending only null bytes; creating new log session'
          next
        end
      end

      puts 'Terminating monitor thread'
    end
  end
end
