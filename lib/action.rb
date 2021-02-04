# frozen_string_literal: true

require 'octokit'
require 'semantic'
# Run action based on the command
class Action
  attr_reader :client, :version_file_path, :repo, :head_branch, :base_branch, :head_sha

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze # rubocop:disable Layout/LineLength
  GEMSPEC_VERSION = Regexp.new(/\.version\s*=\s*/.to_s + SEMVER_VERSION.to_s).freeze
  VALID_SEMVER_LEVELS = %w[minor major patch].freeze

  def initialize(config)
    @client = config.client
    @version_file_path = config.version_file_path
    assign_payload_attributes!(config.payload)
  end

  def bump_version(level)
    if VALID_SEMVER_LEVELS.include?(level)
      content = fetch_content(ref: base_branch, path: version_file_path)

      client.update_contents(repo,
                             version_file_path,
                             "bump #{level} version",
                             head_sha,
                             updated_version_file(content, level),
                             branch: head_branch)
    else
      add_comment_for_invalid_semver
    end
  end

  def fetch_content(ref:, path:)
    content = client.contents(repo, path: path, query: { ref: ref })['content']
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

  def assign_payload_attributes!(payload)
    @repo = payload['repository']['full_name']
    pull_req = client.pull_request(@repo, payload['issue']['number'])
    @head_branch = pull_req['head']['branch']
    @head_sha = pull_req['head']['sha']
    @base_branch = pull_req['base']['branch']
  end
end
