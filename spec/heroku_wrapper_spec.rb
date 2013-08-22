require 'spec_helper'
require_relative '../lib/whacamole/heroku_wrapper'

describe Whacamole::HerokuWrapper do
  let(:h) { Whacamole::HerokuWrapper.new }

  before do
    h.api_token = "foobar"
    h.app_name = "staging"
  end

  describe "authorization" do
    it "base64-encodes the api token and a preceding colon" do
      h.authorization.should == "Basic OmZvb2Jhcg=="
    end
  end

  describe "create_log_session" do
    it "executes a request using the default headers" do
      req = {}
      Net::HTTP::Post.should_receive(:new).with("/apps/staging/log-sessions") { req }
      req.should_receive(:[]=).with("Authorization", h.authorization)
      req.should_receive(:[]=).with("Content-type", "application/json")
      req.should_receive(:[]=).with("Accept", "application/vnd.heroku+json; version=3")
      req.should_receive(:set_form_data).with({'tail' => true})
      Net::HTTP.should_receive(:start).with("api.heroku.com", 443, use_ssl: true).and_return(OpenStruct.new(body: "{\"logplex_url\": \"https://api.heroku.com/log/session/url\"}"))
      h.create_log_session.should == "https://api.heroku.com/log/session/url"
    end
  end

  describe "restart" do
    it "restarts the given process using the legacy api" do
      api = OpenStruct.new
      Heroku::API.should_receive(:new).with(api_key: h.api_token) { api }
      api.should_receive(:post_ps_restart).with(h.app_name, "ps" => "web.2")
      h.restart("web.2")
    end

    it "respects the rate limit" do
      api = OpenStruct.new
      Heroku::API.should_receive(:new).with(api_key: h.api_token) { api }
      api.should_receive(:post_ps_restart).once.with(h.app_name, "ps" => "web.1").ordered
      api.should_receive(:post_ps_restart).once.with(h.app_name, "ps" => "web.2").ordered
      h.restart("web.1")
      h.restart("web.1")
      h.restart("web.2")
    end
  end
end
