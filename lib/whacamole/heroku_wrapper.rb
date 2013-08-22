require 'base64'
require 'net/http'
require 'json'
require 'heroku-api'

module Whacamole
  class HerokuWrapper
    attr_accessor :api_token, :app_name

    RESTART_RATE_LIMIT = 30*60

    def create_log_session
      uri = URI(log_sessions_url)
      req = Net::HTTP::Post.new(uri.path)
      req['Authorization'] = authorization
      req['Content-type'] = content_type
      req['Accept'] = accept
      req.set_form_data({'tail' => true})
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == "https")) {|http| http.request(req)}
      JSON.parse(res.body)['logplex_url']
    end

    def authorization
      "Basic " + Base64.encode64(":#{api_token}").gsub("\n", '')
    end

    def restart(process)
      return if restarts[process] > (Time.now - RESTART_RATE_LIMIT)

      legacy_api.post_ps_restart(app_name, "ps" => process)
      restarts[process] = Time.now
    end

    private
    def content_type
      "application/json"
    end

    def accept
      "application/vnd.heroku+json; version=3"
    end

    def log_sessions_url
      "https://api.heroku.com/apps/#{app_name}/log-sessions"
    end

    def legacy_api
      @legacy_api ||= Heroku::API.new(api_key: api_token)
    end

    def restarts
      @restarts ||= Hash.new { Time.now - RESTART_RATE_LIMIT*2 }
    end
  end
end

