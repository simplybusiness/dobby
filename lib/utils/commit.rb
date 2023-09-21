# frozen_string_literal: true

class Commit
  def initialize(config)
    @config = config
    @client = config.client

    payload = config.payload
    @repo = payload['repository']['full_name']

    pull_req = @client.pull_request(@repo, payload['issue']['number'])
    @head_branch = pull_req['head']['ref']
  end

  def multiple_files(files, commit_message)
    head_branch_ref = "heads/#{@head_branch}"
    ref = @client.ref(@repo, head_branch_ref)
    current_sha = ref.object.sha
    current_tree = @client.commit(@repo, current_sha).commit.tree.sha
    new_tree = @client.create_tree(@repo, files, :base_tree => current_tree)
    new_commit = @client.create_commit(@repo, commit_message, new_tree.sha, current_sha)
    @client.update_ref(@repo, head_branch_ref, new_commit.sha)
  end
end
