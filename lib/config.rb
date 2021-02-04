# frozen_string_literal: true

require 'octokit'
require 'json'

# configuration for octokit
class Config
  attr_reader :client, :payload, :version_file_path, :event_name

  def initialize
    @client = Octokit::Client.new(access_token: ENV['ACCESS_TOKEN'])
    @payload = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
    @event_name = ENV['GITHUB_EVENT_NAME']
    @version_file_path = ENV['VERSION_FILE_PATH']
  end
end
