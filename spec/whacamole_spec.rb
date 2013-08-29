require 'spec_helper'

describe Whacamole do
  describe "configure" do
    it "returns unique config objects by app name" do
      prod_config = nil
      Whacamole.configure("production") do |config|
        prod_config = config
      end

      staging_config = nil
      Whacamole.configure("staging") do |config|
        staging_config = config
      end

      staging_config.app_name.should == "staging"
      prod_config.app_name.should == "production"

      prod_config.should_not == staging_config
    end

    it "returns the same config object if asked a second time" do
      Whacamole.configure("production") do |config|
        config.api_token = "prod token"
      end

      Whacamole.configure("production") do |config|
        config.api_token.should == "prod token"
      end
    end
  end
end

