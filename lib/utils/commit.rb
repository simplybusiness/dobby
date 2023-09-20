# frozen_string_literal: true

class Commit
  attr_reader :file

  def initialize(config)
    @config = config

    payload = config.payload
    @repo = payload['repository']['full_name']
    @file = Struct.new(:path, :mode, :type, :sha)

    pull_req = @client.pull_request(repo, pr_number)
    @head_branch = pull_req['head']['ref']
  end

  def multiple_files(files, commit_message)
    ref = @client.ref(@repo, @head_branch)
    current_sha = ref.object.sha
    current_tree = @client.commit(@repo, current_sha).commit.tree.sha
    new_tree = @client.create_tree(@repo, files, :base_tree => current_tree)
    new_commit = @client.create_commit(@repo, commit_message, new_tree.sha, current_sha)
    @client.update_ref(@repo, @head_branch, new_commit.sha)
  end
end
