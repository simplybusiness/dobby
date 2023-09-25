# frozen_string_literal: true

require 'ostruct'

module Helpers
  module ResponseHelper
    def repo_full_name
      'simplybusiness/test'
    end

    def mock_contents_response(client, version, branch, path = 'lib/version.rb', quote = "'")
      content = {
        'content' => Base64.encode64(
          version_file_content(version, quote)
        ),
        'sha' => 'abc1234'
      }
      allow(client).to receive(:contents)
        .with(repo_full_name, path: path, query: { ref: branch })
        .and_return(content)
    end

    def mock_multiple_files_commit_response(
      client:, version:, head_branch:, base_branch:, files:, commit_message:,
      quote: "'"
    )
      files.each do |file|
        head_branch_ref = "heads/#{head_branch}"
        path = file[:path]

        mock_contents_response(client, version, head_branch, path, quote)
        mock_contents_response(client, version, base_branch, path, quote)
        allow(client).to receive(:ref)
                           .with(repo_full_name, head_branch_ref)
                           .and_return({ 'object' => { 'sha' => "current-ref-sha" } })
        allow(client).to receive(:commit)
                           .with(repo_full_name, "current-ref-sha")
                           .and_return({ 'commit' => { 'tree' => { 'sha' => "current-tree-sha" } } })
        allow(client).to receive(:create_tree)
                           .with(repo_full_name, files, base_tree: "current-tree-sha")
                           .and_return({ 'sha' => "new-tree-sha" })
        allow(client).to receive(:create_commit)
                           .with(repo_full_name, commit_message, "new-tree-sha", "current-ref-sha")
                           .and_return({ 'sha' => "new-ref-sha" })
        allow(client).to receive(:update_ref)
                           .with(repo_full_name, head_branch_ref, "new-ref-sha")
      end
    end

    def mock_reaction_response(client, comment_id, reaction)
      allow(client).to receive(:create_issue_comment_reaction).with(
        repo_full_name, comment_id, reaction
      ).and_return({ id: 1, content: reaction })
    end

    def mock_invalid_reaction_response(client, comment_id, reaction)
      allow(client).to receive(:create_issue_comment_reaction).with(
        repo_full_name, comment_id, reaction
      ).and_raise(Octokit::UnprocessableEntity)
    end

    def version_file_content(version, quote = "'")
      %(
        module TestRepo
          VERSION=#{quote}#{version}#{quote}
        end
       )
    end
  end
end
