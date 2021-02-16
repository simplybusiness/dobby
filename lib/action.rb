# frozen_string_literal: true

require 'octokit'
require 'semantic'
# Run action based on the command
class Action
  attr_reader :client, :version_file_path, :repo, :head_branch, :base_branch, :comment_id

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze # rubocop:disable Layout/LineLength
  GEMSPEC_VERSION = Regexp.new(/\.version\s*=\s*/.to_s + SEMVER_VERSION.to_s).freeze
  VALID_SEMVER_LEVELS = %w[minor major patch].freeze

  def initialize(config)
    @client = config.client
    @version_file_path = config.version_file_path
    payload = config.payload
    @repo = payload['repository']['full_name']
    @comment_id = payload['comment']['id']

    assign_pr_attributes!(payload['issue']['number'])
  end

  def bump_version(level)
    if VALID_SEMVER_LEVELS.include?(level)
      add_reaction('+1')

      content, blob_sha = fetch_content_and_blob_sha(ref: head_branch, path: version_file_path)
      client.update_contents(repo, version_file_path,
                             "bump version #{level}", blob_sha,
                             updated_version_file(content, level),
                             branch: head_branch)
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

  def add_reaction(reaction)
    client.create_issue_comment_reaction(repo, comment_id, reaction)
  end

  private

  def fetch_version(content)
    version = content.match(GEMSPEC_VERSION) || content.match(SEMVER_VERSION)
    Semantic::Version.new(version[0].split('=').last.gsub(/\s/, '').gsub(/'|"/, ''))
  end

  def assign_pr_attributes!(pr_number)
    pull_req = client.pull_request(repo, pr_number)
    @head_branch = pull_req['head']['ref']
    @base_branch = pull_req['base']['ref']
  end
end
