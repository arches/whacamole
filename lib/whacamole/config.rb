module Whacamole
  class Config

    RESTART_TOTAL_THRESHOLD = 1000
    RESTART_RATE_LIMIT = 30*60

    attr_accessor :app_name, :api_token, :event_handler, :dynos, :restart_threshold, :restart_window

    def initialize(app_name)
      self.app_name = app_name
      self.event_handler ||= lambda { |e| puts e.inspect.to_s }
      self.dynos ||= %w{web}
      self.restart_threshold = {total: RESTART_TOTAL_THRESHOLD}
      self.restart_window ||= RESTART_RATE_LIMIT
    end

    def restart_threshold=(value)
      if value.is_a? Integer
        warn "[DEPRECATION] `restart_threshold` should be supplied as a hash. ex.: {total: 500}"
        @restart_threshold = { total: value }
      else
        @restart_threshold = value
      end
    end

  end
end
