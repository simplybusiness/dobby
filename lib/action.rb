# frozen_string_literal: true

require 'octokit'
require 'semantic'
require_relative 'utils/content'
require_relative 'utils/bump'

# Run action based on the command
class Action
  attr_reader :client

  VALID_SEMVER_LEVELS = ['minor', 'major', 'patch'].freeze

  def initialize(config)
    @config = config
    @client = config.client
    payload = config.payload
    @repo = payload['repository']['full_name']
    @comment_id = payload['comment']['id']
  end

  def initiate_version_update(level)
    if VALID_SEMVER_LEVELS.include?(level)
      add_reaction('+1')
      Bump.new(@config, level).bump_everything
    else
      add_reaction('confused')
      puts "::error title=Unknown semver level::The semver level #{level} is not valid"
      "### :boom: Error:boom: \n\n" \
        "The semver level #{level} is not valid so failing the action. " \
        "Expecting a semver level of #{VALID_SEMVER_LEVELS.join(', ')}"
    end
  end

  def add_reaction(reaction)
    client.create_issue_comment_reaction(@repo, @comment_id, reaction)
  end
end
