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
    if @config.require_pr_approval && !pr_approved?
      add_reaction('confused')
      puts "::error title=PR not approved::The PR has not been approved"
      return "### :boom: Error:boom: \n\nThe PR has not been approved so failing the action."
    end

    if VALID_SEMVER_LEVELS.include?(level)
      add_reaction('+1')
      Bump.new(@config, level).bump_everything
    else
      add_reaction('confused')
      puts "::error title=Unknown semver level::The semver level #{level} is not valid"
      "### :boom: Error:boom: \n\nThe semver level #{level} is not valid so failing the action.  Expecting a semver level of #{VALID_SEMVER_LEVELS.join(', ')}"
    end
  end

  def pr_approved?
    reviews = client.pull_request_reviews(@repo, @config.payload['issue']['number'])
    reviews.any? { |review| review['state'] == 'APPROVED' }
  end

  def add_reaction(reaction)
    client.create_issue_comment_reaction(@repo, @comment_id, reaction)
  end
end
