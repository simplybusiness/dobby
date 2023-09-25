# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/utils/content'

describe Content do
  let(:client) { instance_double(Octokit::Client) }
  let(:config) do
    test_config = double
    allow(test_config).to receive_messages(
      client: client, version_file_path: 'lib/version.rb', payload: {
        'repository' => { 'full_name' => repo_full_name },
        'issue' => {
          'number' => 1
        },
        'comment' => {
          'id' => 123
        }
      }
    )
    test_config
  end
  let(:content) { Content.new(config: config, ref: 'master', path: 'lib/version.rb') }

  it 'fetch the content for a given file on a branch' do
    mock_contents_response(client, '1.0.0', 'master')
    expect(client).to receive(:contents).with(
      repo_full_name,
      path: 'lib/version.rb',
      query: { ref: 'master' }
    )
    fetched_content = content.content
    expect(fetched_content).to eq(version_file_content('1.0.0'))
  end

  it 'fetch the blob_sha for a given file on a branch' do
    mock_contents_response(client, '1.0.0', 'master')
    expect(client).to receive(:contents).with(
      repo_full_name,
      path: 'lib/version.rb',
      query: { ref: 'master' }
    )
    fetched_content = content.blob_sha
    expect(fetched_content).to eq('abc1234')
  end
end
