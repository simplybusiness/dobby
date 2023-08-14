# frozen_string_literal: true

module Helpers
  module ResponseHelper
    def repo_full_name
      'simplybusiness/test'
    end

    def mock_version_response(client, version, branch)
      content = {
        'content' => Base64.encode64(
          version_file_content(version)
        ),
        'sha' => 'abc1234'
      }
      allow(client).to receive(:contents)
        .with(repo_full_name, path: 'lib/version.rb', query: { ref: branch })
        .and_return(content)
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

    def version_file_content(version, quote = '\'')
      %(
        module TestRepo
          VERSION=#{quote}#{version}#{quote}
        end
       )
    end
  end
end
