# frozen_string_literal: true

require_relative 'content'
require_relative 'commit'

class Bump
  SEMVER = /
    ["']?                # Optional quotes
    (0|[1-9]\d*)         # Major version
    \.                   # Dot separator
    (0|[1-9]\d*)         # Minor version
    \.                   # Dot separator
    (0|[1-9]\d*)         # Patch version
    (?:-                 # Optional pre-release
      (
        (?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*) # Pre-release identifier
        (?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))* # Additional identifiers
      )
    )?
    (?:\+                # Optional build metadata
      (
        [0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)* # Build metadata identifiers
      )
    )?
    ["']?                # Optional quotes
  /x

  SEPARATOR = /
    \s*                  # Optional whitespace
    [:=]                 # Separator (colon or equals)
    \s*                  # Optional whitespace
  /x

  VERSION_KEY = /
    (?:^_+|^|\.|\s|"|')  # Optional prefix
    (?:base|version)     # Key name
    (?:["']*|_+)         # Optional suffix
  /x

  VERSION_SETTING = /
    #{VERSION_KEY.source} # Match version key
    #{SEPARATOR.source}   # Match separator
    #{SEMVER.source}      # Match semantic version
  /ix

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
    files_messages = {}

    @other_version_file_paths.push(@version_file_path).each do |version_file_path|
      content_update = get_content_update(version_file_path)
      files.push(content_update) if content_update
      files_messages[version_file_path] = content_update ? update_message : no_update_message(version_file_path)
    end

    commit.multiple_files(files, "Bump #{@level} version") if files.any?
    generate_message(files_messages)
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

  def get_content_update(path)
    head_branch_content = Content.new(config: @config, ref: @head_branch, path: path).content
    updated_base_branch_content = head_branch_content.gsub @version.to_s, @updated_version.to_s

    if head_branch_content == updated_base_branch_content
      puts "::notice title=Nothing to update::The desired version bump is already present for: #{path}"
      return nil
    end

    { :path => path, :mode => '100644', :type => 'blob', :content => updated_base_branch_content }
  end

  def fetch_version(content)
    version = content.content.match(VERSION_SETTING)
    Semantic::Version.new(version[0].split(SEPARATOR).last.gsub(/\s/, '').gsub(/'|"/, ''))
  end

  def bump_version(version, level)
    version.increment!(level.to_sym)
  end

  def generate_message(files_messages)
    message = "### Bump version from #{@version} to #{@updated_version}\n" \
              "Dobby has attempted to update the following files\n" \
              "| File Name | Message |\n" \
              "|-----------|---------|\n"
    files_messages.each do |file_name, msg|
      message += "| #{file_name} | #{msg} |\n"
    end
    message
  end

  def no_update_message(path)
    "Nothing to update as the desired version bump is already present for: #{path}"
  end

  def update_message
    "Bump #{@level} version from #{@version} to #{@updated_version}"
  end
end
