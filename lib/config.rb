# frozen_string_literal: true

require 'octokit'
require 'json'
require 'jwt'
require 'openssl'

TEN_MINUTES = 600 # seconds

# configuration for octokit
class Config
  attr_reader :client, :payload, :version_file_path, :other_version_file_paths, :event_name

  def initialize
    @payload = JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH')))
    @event_name = ENV.fetch('GITHUB_EVENT_NAME')
    @version_file_path = ENV.fetch('VERSION_FILE_PATH').sub('./', '')
    @other_version_file_paths = ENV.fetch('OTHER_VERSION_FILE_PATHS', "").split(",")
    @client = Octokit::Client.new(access_token: access_token)
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
      exp: Time.now.to_i + TEN_MINUTES,
      iss: ENV.fetch('DOBBY_APP_ID')
    }

    private_key = OpenSSL::PKey::RSA.new(ENV.fetch('DOBBY_PRIVATE_KEY'))

    JWT.encode(payload, private_key, 'RS256')
  end
end
