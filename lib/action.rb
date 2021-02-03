# frozen_string_literal: true

require 'octokit'
require 'semantic'
# Run action based on the command
class Action
  attr_reader :client, :payload, :version_file_path, :repo

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze # rubocop:disable Layout/LineLength
  GEMSPEC_VERSION = Regexp.new(/\.version\s*=\s*/.to_s + SEMVER_VERSION.to_s).freeze
  VALID_SEMVER_LEVELS = %w[minor major patch].freeze

  def initialize(config)
    @client = config.client
    @payload = config.payload
    @version_file_path = config.version_file_path
    @repo = payload['repository']['full_name']
  end

  def update_version(level)
    if VALID_SEMVER_LEVELS.include?(level)
      content = fetch_content(ref: 'master')
      client.update_contents(
        repo: repo,
        message: "bump #{level} version",
        content: updated_version_file(content, level),
        branch: 'asdasd'
      )
    else
      add_comment_for_invalid_semver
    end
  end

  def fetch_content(ref:)
    content = client.contents(repo, path: version_file_path, query: { ref: ref })['content']
    Base64.decode64(content)
  end

  def updated_version_file(content, level)
    version = fetch_version(content)
    updated_version = version.increment!(level.to_sym)
    content.gsub(SEMVER_VERSION, "'#{updated_version}'")
  end

  private

  def fetch_version(content)
    version = content.match(GEMSPEC_VERSION) || content.match(SEMVER_VERSION)
    Semantic::Version.new(version[0].split('=').last.gsub(/\s/, '').gsub(/'|"/, ''))
  end

  def add_comment_for_invalid_semver; end
end
