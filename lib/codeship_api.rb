require "codeship_api/version"
require 'net/http'
require 'json'
require 'pry'

module CodeshipApi
  ROOT = 'https://api.codeship.com/v2/'
  class Error < StandardError; end
  # Your code goes here...

  def self.token
    @token ||= get_token
  end

  def self.get_token
    post("/auth")
  end

  private

  def self.auth_post(path, params={}, headers={})
    post(path, params, headers.merge({"Authorization" => "Bearer #{token}"}))
  end

  def self.post(path, params={}, headers={})
    uri = URI(ROOT + path.sub(/^\//, ''))

    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }.merge(headers)

    res = Net::HTTP.post(uri, params.to_json, headers)
  end
end
