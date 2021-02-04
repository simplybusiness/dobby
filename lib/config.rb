# frozen_string_literal: true

require 'octokit'
require 'json'

# configuration for octokit
class Config
  attr_reader :client, :payload, :version_file_path

  def initialize
    @client = Octokit::Client.new(access_token: ENV['ACCESS_TOKEN'])
    @payload = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
    @version_file_path = ENV['VERSION_FILE_PATH']
  end
end
