require 'spec_helper'

describe Whacamole::Config do
  describe "initialization" do
    it "sets the app name" do
      c = Whacamole::Config.new("production")
      c.app_name.should == "production"
    end

    it "sets default dyno to watch to web" do
      c = Whacamole::Config.new("production")
      c.dynos.should == %w{web}
    end
  end
end
