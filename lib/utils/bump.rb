# frozen_string_literal: true

require_relative 'content'
require_relative 'commit'

class Bump
  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/ # rubocop:disable Layout/LineLength
  GEMSPEC_VERSION = Regexp.new(/\.version\s*=\s*/.to_s + SEMVER_VERSION.to_s).freeze

  def initialize(config, level)
    @config = config
    @level = level
    payload = config.payload
    @client = config.client
    @version_file_path = config.version_file_path
    @other_version_file_paths = config.other_version_file_paths
    @repo = payload['repository']['full_name']
    assign_pr_attributes!(payload['issue']['number'])
    calculate_bumping_data!
  end

  def bump_everything
    commit = Commit.new(@config)
    files = []
    @other_version_file_paths.push(@version_file_path).each do |version_file_path|
      base_branch_content = Content.new(config: @config, ref: @base_branch, path: version_file_path)
      head_branch_content = Content.new(config: @config, ref: @head_branch, path: version_file_path)
      updated_base_branch_content = base_branch_content.content.gsub @version.to_s, @updated_version.to_s

      if head_branch_content.content == updated_base_branch_content
        puts "::notice title=Nothing to update::The desired version bump is already present for: #{version_file_path}"
      else
        files.push(
          {
            :path => version_file_path, :mode => '100644', type => 'blob', :content => updated_base_branch_content
          }
        )
      end
    end
    commit.multiple_files(files, "Bump #{@level} version")
  end

  private

  def calculate_bumping_data!
    base_branch_content = Content.new(config: @config, ref: @base_branch, path: @version_file_path)
    @version = fetch_version(base_branch_content)
    @updated_version = bump_version(@version, @level)
  end

  def assign_pr_attributes!(pr_number)
    pull_req = @client.pull_request(@repo, pr_number)
    @head_branch = pull_req['head']['ref']
    @base_branch = pull_req['base']['ref']
  end

  def fetch_version(content)
    version = content.content.match(GEMSPEC_VERSION) || content.content.match(SEMVER_VERSION)
    Semantic::Version.new(version[0].split('=').last.gsub(/\s/, '').gsub(/'|"/, ''))
  end

  def bump_version(version, level)
    version.increment!(level.to_sym)
  end
end
