# frozen_string_literal: true

require 'octokit'

# Run action based on the command
class Action
  attr_reader :client, :payload, :version_file_path, :repo

  SEMVER_LEVELS = %w[minor major patch].freeze
  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze # rubocop:disable Layout/LineLength
  GEMSPEC_VERSION = Regexp.new(/\.version\s*=\s*/.to_s + SEMVER_VERSION.to_s).freeze

  def initialize(config)
    @client = config.client
    @payload = config.payload
    @version_file_path = config.version_file_path
    @repo = payload['repository']['full_name']
  end

  def update_version(level)
    msg = "#{level} is not valid semver. Please provide one of #{SEMVER_LEVELS.join(', ')} level"
    raise ArgumentError, msg unless SEMVER_LEVELS.include?(level)
  end

  def fetch_version(ref:)
    content = client.contents(repo, path: version_file_path, query: { ref: ref })['content']
    content = Base64.decode64(content)
    version = content.match(GEMSPEC_VERSION) || content.match(SEMVER_VERSION)
    format_version(version)
  end

  private

  def format_version(version)
    Gem::Version.new(version[0].split('=').last.gsub(/\s/, '').gsub(/'|"/, ''))
  end
end
