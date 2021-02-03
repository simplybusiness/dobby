# frozen_string_literal: true

require 'ostruct'
require_relative '../spec_helper'
# rubocop:disable Metrics/BlockLength
describe Action do
  let(:client) { instance_double(Octokit::Client) }

  let(:config) do
    OpenStruct.new(
      client: client,
      version_file_path: 'lib/version.rb',
      payload: {
        'repository' => { 'full_name' => 'simplybusiness/test' },
        'pull_request' => {
          'number' => 1,
          'head' => { 'branch' => 'my_branch' },
          'base' => { 'branch' => 'master' }
        }
      }
    )
  end

  let(:action) { Action.new(config) }

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
  end

  describe '#fetch_content' do
    it 'fetch the content for a given file on a branch' do
      mock_version_response('1.0.0', 'master')
      expect(client).to receive(:contents).with(
        'simplybusiness/test',
        path: 'lib/version.rb',
        query: { ref: 'master' }
      )
      content = action.fetch_content(ref: 'master', path: 'lib/version.rb')
      expect(content).to eq(version_file_content('1.0.0'))
    end
  end

  describe '#bump_version' do
    it 'add a comment for invalid semver' do
      expect(action).to receive(:add_comment_for_invalid_semver)
      action.bump_version('invalid_semver')
    end

    it 'updates the version file with new version' do
      mock_version_response('1.0.0', 'master')
      updated_content = version_file_content('1.1.0')
      expect(client).to receive(:update_contents).with(
        repo: 'simplybusiness/test',
        message: 'bump minor version',
        content: updated_content,
        branch: 'my_branch'
      )
      action.bump_version('minor')
    end
  end

  private

  def mock_version_response(version, branch)
    content = {
      'content' => Base64.encode64(
        version_file_content(version)
      )
    }
    allow(client).to receive(:contents)
      .with('simplybusiness/test', path: 'lib/version.rb', query: { ref: branch })
      .and_return(content)
  end

  def version_file_content(version)
    %(
      module TestRepo
        VERSION='#{version}'
      end
     )
  end
end
# rubocop:enable Metrics/BlockLength
