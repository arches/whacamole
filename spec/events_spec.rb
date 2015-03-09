require 'spec_helper'

describe "DynoSize" do
  let (:e) { Whacamole::Events::DynoSize.new }

  describe "setting total_size" do
    it "converts strings to floats" do
      e.total_size = "766.65"
      e.total_size.should == 766.65
    end
  end

  describe "setting swap_size" do
    it "does not convert nil values" do
      e.total_size = nil
      e.total_size.should == nil
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
      e = Whacamole::Events::DynoSize.new({:total_size => "766.65", swap_size: "34.5", :units => "MB", :process => "web.2"})
      e.swap_size.should == 34.5
      e.total_size.should == 766.65
      e.units.should == "MB"
      e.process.should == "web.2"
    end
  end
end

