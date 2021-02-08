# frozen_string_literal: true

module Helpers
  module ResponseHelper
    def mock_version_response(client, version, branch)
      content = {
        'content' => Base64.encode64(
          version_file_content(version)
        ),
        'sha' => 'abc1234'
      }
      allow(client).to receive(:contents)
        .with('simplybusiness/test', path: 'lib/version.rb', query: { ref: branch })
        .and_return(content)
    end

    def mock_reaction_response(client, comment_id, reaction)
      allow(client).to receive(:create_issue_comment_reaction).with(
        'simplybusiness/test', comment_id, reaction
      ).and_return({ id: 1, content: reaction })
    end

    def version_file_content(version)
      %(
        module TestRepo
          VERSION='#{version}'
        end
       )
    end
  end
end
