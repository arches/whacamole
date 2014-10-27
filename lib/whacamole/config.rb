module Whacamole
  class Config
    attr_accessor :app_name, :api_token, :event_handler, :dynos

    def initialize(app_name)
      self.app_name = app_name
      self.event_handler ||= lambda { |e| puts e.inspect.to_s }
      self.dynos ||= %w{web}
    end
  end
end
