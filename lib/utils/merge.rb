# frozen_string_literal: true

# Merge base branch into head branch of a PR
class Merge
  def initialize(config)
    @config = config
    @client = config.client
    payload = config.payload
    @repo = payload['repository']['full_name']
    pr_number = payload['issue']['number']
    pull_req = @client.pull_request(@repo, pr_number)
    @head_branch = pull_req['head']['ref']
    @base_branch = pull_req['base']['ref']
  end

  def merge_base_into_head
    puts "::notice title=Merging::Merging #{@base_branch} into #{@head_branch}"
    begin
      result = @client.merge(
        @repo, @head_branch, @base_branch,
        commit_message: "Merge #{@base_branch} into #{@head_branch}"
      )
      if result
        puts "::notice title=Merge successful::Successfully merged #{@base_branch} into #{@head_branch}"
        { success: true, message: "Successfully merged #{@base_branch} into #{@head_branch}" }
      else
        puts "::notice title=Already up to date::Branch #{@head_branch} is already up to date with #{@base_branch}"
        { success: true, message: "Branch #{@head_branch} is already up to date with #{@base_branch}" }
      end
    rescue Octokit::Conflict => e
      puts "::error title=Merge conflict::Failed to merge #{@base_branch} into #{@head_branch}: #{e.message}"
      { success: false, message: "Failed to merge #{@base_branch} into #{@head_branch}: merge conflict detected" }
    rescue StandardError => e
      puts "::error title=Merge failed::Failed to merge #{@base_branch} into #{@head_branch}: #{e.message}"
      { success: false, message: "Failed to merge #{@base_branch} into #{@head_branch}: #{e.message}" }
    end
  end
end
