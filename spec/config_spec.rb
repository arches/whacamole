require 'spec_helper'

describe Whacamole::Config do
  describe "initialization" do
    it "sets the app name" do
      c = Whacamole::Config.new("production")
      c.app_name.should == "production"
    end
    it "has a default restart_threshold" do
      c = Whacamole::Config.new("production")
      c.restart_threshold.should == 1000
    end
  end
end

