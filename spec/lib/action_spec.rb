# frozen_string_literal: true

require 'ostruct'
require_relative '../spec_helper'
describe Action do
  let(:client) { instance_double(Octokit::Client) }
  let(:prefer_double_quotes) { false }

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
      }, prefer_double_quotes: prefer_double_quotes
    )
    test_config
  end

  let(:action) { Action.new(config) }

  before do
    allow(client).to receive(:pull_request)
      .and_return({
                    'head' => { 'ref' => 'my_branch' },
                    'base' => { 'ref' => 'master' }
                  })
  end

  describe '#updated_version_file' do
    let(:content) { version_file_content('1.0.0') }

    it 'bumps the major version' do
      expected_content = version_file_content('2.0.0')
      updated_content = action.updated_version_file(content, 'major')
      expect(updated_content).to eq(expected_content)
    end

    it 'bumps the minor version' do
      expected_content = version_file_content('1.1.0')
      updated_content = action.updated_version_file(content, 'minor')
      expect(updated_content).to eq(expected_content)
    end

    it 'bumps the patch version' do
      expected_content = version_file_content('1.0.1')
      updated_content = action.updated_version_file(content, 'patch')
      expect(updated_content).to eq(expected_content)
    end

    context 'when prefer_double_quotes configuration options is enabled' do
      let(:prefer_double_quotes) { true }

      it 'encloses the new version value in double quotes' do
        expected_content = version_file_content('1.0.1', '"')
        updated_content = action.updated_version_file(content, 'patch')
        expect(updated_content).to eq(expected_content)
      end
    end
  end

  describe '#fetch_content' do
    it 'fetch the content for a given file on a branch' do
      mock_version_response(client, '1.0.0', 'master')
      expect(client).to receive(:contents).with(
        repo_full_name,
        path: 'lib/version.rb',
        query: { ref: 'master' }
      )
      content = action.fetch_content(ref: 'master', path: 'lib/version.rb')
      expect(content).to eq(version_file_content('1.0.0'))
    end
  end

  describe '#fetch_blob_sha' do
    it 'fetch the blob_sha for a given file on a branch' do
      mock_version_response(client, '1.0.0', 'master')
      expect(client).to receive(:contents).with(
        repo_full_name,
        path: 'lib/version.rb',
        query: { ref: 'master' }
      )
      content = action.fetch_blob_sha(ref: 'master', path: 'lib/version.rb')
      expect(content).to eq('abc1234')
    end
  end

  describe '#initiate_version_update' do
    it 'reacts with confused emoji for invalid semver' do
      expect(action).to receive(:add_reaction).with('confused')
      action.initiate_version_update('invalid_semver')
    end

    it 'updates the version file with new version and react with thumbs up' do
      mock_version_response(client, '1.0.0', 'my_branch')
      mock_version_response(client, '1.0.0', 'master')
      updated_content = version_file_content('1.1.0')
      expect(client).to receive(:update_contents).with(
        repo_full_name,
        'lib/version.rb',
        'bump minor version',
        'abc1234',
        updated_content,
        branch: 'my_branch'
      )
      expect(action).to receive(:add_reaction).with('+1')
      action.initiate_version_update('minor')
    end
  end

  describe '#add_reaction' do
    it 'add reaction to the comment' do
      mock_reaction_response(client, 123, '+1')
      response = action.add_reaction('+1')
      expect(response).to eq({ id: 1, content: '+1' })
    end

    it 'raise exception for invalid reaction' do
      mock_invalid_reaction_response(client, 123, 'barney_cry')
      expect do
        action.add_reaction('barney_cry')
      end.to raise_error(Octokit::UnprocessableEntity)
    end
  end
end
