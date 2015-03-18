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

    it "has a default total restart threshold" do
      c = Whacamole::Config.new("production")
      c.restart_threshold[:total].should == 1000
    end

    it "can be set with a legacy restart treshold value" do
      c = Whacamole::Config.new("production")
      c.restart_threshold = 500
      c.restart_threshold.should == {total: 500}
    end

    it "has no swap restart threshold" do
      c = Whacamole::Config.new("production")
      c.restart_threshold[:swap].should == nil
    end
  end
end
