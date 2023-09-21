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
    ref = @client.ref(@repo, "heads/#{@head_branch}")
    current_sha = ref.object.sha
    current_tree = @client.commit(@repo, current_sha).commit.tree.sha
    new_tree = @client.create_tree(@repo, files, :base_tree => current_tree)
    new_commit = @client.create_commit(@repo, commit_message, new_tree.sha, current_sha)
    puts 'TEMP_KARAN', new_commit.sha
    @client.update_ref(@repo, @head_branch, new_commit.sha)
  end
end
