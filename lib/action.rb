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
    @repo = config.payload['repository']['full_name']

    assign_pr_attributes!(config.payload['issue']['number'])
  end

  def bump_version(level)
    if VALID_SEMVER_LEVELS.include?(level)
      content, blob_sha = fetch_content_and_blob_sha(ref: head_branch, path: version_file_path)
      client.update_contents(repo, version_file_path,
                             "bump #{level} version",
                             blob_sha,
                             updated_version_file(content, level),
                             branch: head_branch)
      add_reaction('+1')
    else
      add_reaction('confused')
    end
  end

  def fetch_content_and_blob_sha(ref:, path:)
    content = client.contents(repo, path: path, query: { ref: ref })
    [Base64.decode64(content['content']), content['sha']]
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

  def add_reaction(content)

  end

  def assign_pr_attributes!(pr_number)
    pull_req = client.pull_request(repo, pr_number)
    @head_branch = pull_req['head']['ref']
    @base_branch = pull_req['base']['ref']
  end
end
