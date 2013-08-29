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
end
