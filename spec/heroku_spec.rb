require 'spec_helper'
require_relative '../lib/whacamole/heroku'

describe Whacamole::Heroku do
  let(:h) { Whacamole::Heroku.new }

  before do
    h.api_token = "foobar"
    h.app_name = "a50-staging"
  end

  describe "authorization" do
    it "base64-encodes the api token and a preceding colon" do
      h.authorization.should == "Basic OmZvb2Jhcg=="
    end
  end

  describe "create_log_session" do
    it "executes a request using the default headers" do
      req = {}
      Net::HTTP::Post.should_receive(:new).with("/apps/a50-staging/log-sessions") { req }
      req.should_receive(:[]=).with("Authorization", h.authorization)
      req.should_receive(:[]=).with("Content-type", "application/json")
      req.should_receive(:[]=).with("Accept", "application/vnd.heroku+json; version=3")
      req.should_receive(:set_form_data).with({'tail' => true})
      Net::HTTP.should_receive(:start).with("api.heroku.com", 443, use_ssl: true).and_return(OpenStruct.new(body: "{\"logplex_url\": \"https://api.heroku.com/log/session/url\"}"))
      h.create_log_session.should == "https://api.heroku.com/log/session/url"
    end
  end
end
