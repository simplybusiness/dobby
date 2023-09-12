# frozen_string_literal: true

require 'octokit'
require 'semantic'
# Run action based on the command
class Action
  attr_reader :client, :version_file_path, :other_version_file_paths, :repo, :head_branch, :base_branch, :comment_id,
              :prefer_double_quotes

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/ # rubocop:disable Layout/LineLength
  GEMSPEC_VERSION = Regexp.new(/\.version\s*=\s*/.to_s + SEMVER_VERSION.to_s).freeze
  VALID_SEMVER_LEVELS = ['minor', 'major', 'patch'].freeze

  def initialize(config)
    @client = config.client
    @version_file_path = config.version_file_path
    payload = config.payload
    @other_version_file_paths = config.other_version_file_paths
    @repo = payload['repository']['full_name']
    @comment_id = payload['comment']['id']
    @prefer_double_quotes = config.prefer_double_quotes

    assign_pr_attributes!(payload['issue']['number'])
  end

  def initiate_version_update(level)
    if VALID_SEMVER_LEVELS.include?(level)
      add_reaction('+1')

      base_branch_content = fetch_content(ref: base_branch, path: version_file_path)
      head_branch_content = fetch_content(ref: head_branch, path: version_file_path)
      head_branch_blob_sha = fetch_blob_sha(ref: head_branch, path: version_file_path)

      version = fetch_version(base_branch_content)
      updated_version = fetch_bumped_version(version, level)

      updated_content = updated_version_file(base_branch_content, updated_version)
      check_and_bump_version(level, head_branch_content, head_branch_blob_sha, updated_content)

      bump_other_version_files(base_branch, head_branch, version, updated_version)
    else
      add_reaction('confused')
      puts "::error title=Unknown semver level::The semver level #{level} is not valid"
    end
  end

  def fetch_content(ref:, path:)
    begin
      content = client.contents(repo, path: path, query: { ref: ref })
    rescue Octokit::NotFound => e
      puts "::error file=#{path},title=Error fetching file #{path}::#{e.message} "
      raise e
    end
    Base64.decode64(content['content'])
  end

  def fetch_blob_sha(ref:, path:)
    content = client.contents(repo, path: path, query: { ref: ref })
    content['sha']
  end

  def updated_version_file(content, updated_version)
    quote = prefer_double_quotes ? '"' : "'"
    content.gsub(SEMVER_VERSION, "#{quote}#{updated_version}#{quote}")
  end

  def add_reaction(reaction)
    client.create_issue_comment_reaction(repo, comment_id, reaction)
  end

  private

  def check_and_bump_version(level, head_branch_content, head_branch_blob_sha, updated_content)
    if head_branch_content == updated_content
      puts '::notice title=Nothing to update::Nothing to update, the desired version bump is already present'
    else
      client.update_contents(
        repo, version_file_path,
        "bump #{level} version", head_branch_blob_sha,
        updated_content,
        branch: head_branch
      )
    end
  end

  def bump_other_version_files(base_branch, head_branch, version, updated_version)
    other_version_file_paths.each do |version_file_path|
      base_branch_content = fetch_content(ref: base_branch, path: version_file_path)
      head_branch_content = fetch_content(ref: head_branch, path: version_file_path)
      head_branch_blob_sha = fetch_blob_sha(ref: head_branch, path: version_file_path)

      update_base_branch_content = base_branch_content.gsub version.to_s, updated_version.to_s

      if head_branch_content == update_base_branch_content
        puts "::notice title=Nothing to update::The desired version bump is already present for: #{version_file_path}"
      else
        client.update_contents(
          repo, version_file_path,
          "Bump #{version} to #{updated_version}",
          head_branch_blob_sha,
          update_base_branch_content,
          branch: head_branch
        )
      end
    end
  end

  def fetch_version(content)
    version = content.match(GEMSPEC_VERSION) || content.match(SEMVER_VERSION)
    Semantic::Version.new(version[0].split('=').last.gsub(/\s/, '').gsub(/'|"/, ''))
  end

  def fetch_bumped_version(version, level)
    version.increment!(level.to_sym)
  end

  def assign_pr_attributes!(pr_number)
    pull_req = client.pull_request(repo, pr_number)
    @head_branch = pull_req['head']['ref']
    @base_branch = pull_req['base']['ref']
  end
end
