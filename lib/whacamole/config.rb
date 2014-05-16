module Whacamole
  class Config

    RESTART_THRESHOLD = 1000

    attr_accessor :app_name, :api_token, :event_handler, :dynos, :restart_threshold

    def initialize(app_name)
      self.app_name = app_name
      self.event_handler ||= lambda { |e| puts e.inspect.to_s }
      self.dynos ||= %w{web}
      self.restart_threshold ||= RESTART_THRESHOLD
    end
  end
end
