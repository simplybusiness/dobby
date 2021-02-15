# frozen_string_literal: true

require 'octokit'
require 'json'
require 'jwt'

# configuration for octokit
class Config
  attr_reader :client, :payload, :version_file_path, :event_name

  def initialize
    @client = Octokit::Client.new(access_token: access_token)
    @payload = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
    @event_name = ENV['GITHUB_EVENT_NAME']
    @version_file_path = ENV['VERSION_FILE_PATH']
  end

  private

  def access_token
    bearer_client = Octokit::Client.new(bearer_token: bearer_token)
    installation = bearer_client.find_repository_installation(payload['repository']['full_name'])
    response = bearer_client.create_app_installation_access_token(installation[:id])
    response[:token]
  end

  def bearer_token
    payload = {
      iat: Time.now.to_i,
      exp: Time.now.to_i + (10 * 60),
      iss: ENV['DOBBY_APP_ID']
    }
    private_key = OpenSSL::PKey::RSA.new(ENV['DOBBY_PRIVATE_KEY'])

    JWT.encode(payload, private_key, 'RS256')
  end
end
