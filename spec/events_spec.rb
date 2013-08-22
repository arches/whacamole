require 'spec_helper'
require_relative '../lib/whacamole/events'

describe "DynoSize" do
  let (:e) { Whacamole::Events::DynoSize.new }

  describe "setting size" do
    it "converts strings to floats" do
      e.size = "766.65"
      e.size.should == 766.65
    end
  end

  describe "setting units" do
    it "stores the units on the object" do
      e.units = "MB"
      e.units.should == "MB"
    end
  end

  describe "setting process" do
    it "stores the process on the object" do
      e.process = "web.2"
      e.process.should == "web.2"
    end
  end

  describe "initialization" do
    it "sets the variables from the input hash" do
      e = Whacamole::Events::DynoSize.new({size: "766.65", units: "MB", process: "web.2"})
      e.size.should == 766.65
      e.units.should == "MB"
      e.process.should == "web.2"
    end
  end
end

