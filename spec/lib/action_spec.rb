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
        'issue' => {
          'number' => 1
        }
      }
    )
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
  end

  describe '#fetch_content' do
    it 'fetch the content for a given file on a branch' do
      mock_version_response('1.0.0', 'master')
      expect(client).to receive(:contents).with(
        'simplybusiness/test',
        path: 'lib/version.rb',
        query: { ref: 'master' }
      )
      content = action.fetch_content_and_blob_sha(ref: 'master', path: 'lib/version.rb')
      expect(content).to eq([version_file_content('1.0.0'), 'abc1234'])
    end
  end

  describe '#bump_version' do
    it 'react with confused emoji for invalid semver' do
      expect(action).to receive(:add_reaction).with('confused')
      action.bump_version('invalid_semver')
    end

    it 'updates the version file with new version and react with thumbs up' do
      mock_version_response('1.0.0', 'my_branch')
      updated_content = version_file_content('1.1.0')
      expect(client).to receive(:update_contents).with(
        'simplybusiness/test',
        'lib/version.rb',
        'bump minor version',
        'abc1234',
        updated_content,
        branch: 'my_branch'
      )
      expect(action).to receive(:add_reaction).with('+1')
      action.bump_version('minor')
    end
  end

  private

  def mock_version_response(version, branch)
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

  def version_file_content(version)
    %(
      module TestRepo
        VERSION='#{version}'
      end
     )
  end
end
# rubocop:enable Metrics/BlockLength
