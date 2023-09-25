# frozen_string_literal: true

require 'ostruct'
require_relative '../spec_helper'
describe Action do
  let(:client) { instance_double(Octokit::Client) }
  let(:other_version_file_paths) { [] }

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
      }, other_version_file_paths: other_version_file_paths
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

  describe '#initiate_version_update' do
    it 'reacts with confused emoji for invalid semver' do
      expect(action).to receive(:add_reaction).with('confused')
      action.initiate_version_update('invalid_semver')
    end

    it 'bumps major version' do
      updated_content = version_file_content('2.0.0')
      files = [
        {
          :path => 'lib/version.rb', :mode => '100644', :type => 'blob', :content => updated_content
        }
      ]
      mock_multiple_files_commit_response(
        client: client, version: '1.3.4', files: files, commit_message: "Bump major version",
        head_branch: 'my_branch', base_branch: 'master'
      )
      expect(client).to receive(:create_tree).with(
        repo_full_name,
        files,
        base_tree: "current-tree-sha"
      )
      expect(action).to receive(:add_reaction).with('+1')
      action.initiate_version_update('major')
    end

    it 'bumps minor version' do
      mock_contents_response(client, '1.3.4', 'my_branch')
      mock_contents_response(client, '1.3.4', 'master')
      updated_content = version_file_content('1.4.0')
      expect(client).to receive(:update_contents).with(
        repo_full_name,
        'lib/version.rb',
        'Bump minor version',
        'abc1234',
        updated_content,
        branch: 'my_branch'
      )
      expect(action).to receive(:add_reaction).with('+1')
      action.initiate_version_update('minor')
    end

    it 'bumps patch version' do
      mock_contents_response(client, '1.3.4', 'my_branch')
      mock_contents_response(client, '1.3.4', 'master')
      updated_content = version_file_content('1.3.5')
      expect(client).to receive(:update_contents).with(
        repo_full_name,
        'lib/version.rb',
        'Bump patch version',
        'abc1234',
        updated_content,
        branch: 'my_branch'
      )
      expect(action).to receive(:add_reaction).with('+1')
      action.initiate_version_update('patch')
    end

    it 'maintains double quotes' do
      mock_contents_response(client, '1.3.4', 'my_branch', 'lib/version.rb', '"')
      mock_contents_response(client, '1.3.4', 'master', 'lib/version.rb', '"')
      updated_content = version_file_content('1.3.5', '"')
      expect(client).to receive(:update_contents).with(
        repo_full_name,
        'lib/version.rb',
        'Bump patch version',
        'abc1234',
        updated_content,
        branch: 'my_branch'
      )
      expect(action).to receive(:add_reaction).with('+1')
      action.initiate_version_update('patch')
    end

    context 'when other version files need to be changed' do
      let(:other_version_file_paths) { ['package.json', 'docs/index.md'] }

      it 'bumps every file specified' do
        mock_contents_response(client, '1.3.4', 'my_branch')
        mock_contents_response(client, '1.3.4', 'master')
        mock_contents_response(client, '1.3.4', 'my_branch', 'package.json')
        mock_contents_response(client, '1.3.4', 'master', 'package.json')
        mock_contents_response(client, '1.3.4', 'my_branch', 'docs/index.md')
        mock_contents_response(client, '1.3.4', 'master', 'docs/index.md')
        updated_content = version_file_content('2.0.0')
        expect(client).to receive(:update_contents).with(
          repo_full_name,
          'lib/version.rb',
          'Bump major version',
          'abc1234',
          updated_content,
          branch: 'my_branch'
        ).once
        expect(client).to receive(:update_contents).with(
          repo_full_name,
          'package.json',
          'Bump major version',
          'abc1234',
          updated_content,
          branch: 'my_branch'
        ).once
        expect(client).to receive(:update_contents).with(
          repo_full_name,
          'docs/index.md',
          'Bump major version',
          'abc1234',
          updated_content,
          branch: 'my_branch'
        ).once
        expect(action).to receive(:add_reaction).with('+1')
        action.initiate_version_update('major')
      end
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
