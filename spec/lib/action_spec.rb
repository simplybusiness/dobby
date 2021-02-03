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
          'head' => { 'branch' => 'my_branch', 'sha' => '1111' },
          'base' => { 'branch' => 'master' }
        }
      }
    )
  end

  let(:action) { Action.new(config) }

  it 'returns the gem version for a given branch' do
    mock_version_response('1.0.0', 'master')
    version = Gem::Version.new('1.0.0')

    expect(action.fetch_version(ref: 'master')).to eq(version)
  end

  it 'bumps the major version in version file' do
    content = version_file_content('1.0.0')
    expected_content = version_file_content('2.0.0')
    updated_content = action.bump_version_file(content, 'major')
    expect(updated_content).to eq(expected_content)
  end

  it 'bumps the minor version in version file' do
    content = version_file_content('1.0.0')
    expected_content = version_file_content('1.1.0')
    updated_content = action.bump_version_file(content, 'minor')
    expect(updated_content).to eq(expected_content)
  end

  it 'bumps the patch version in version file' do
    content = version_file_content('1.0.0')
    expected_content = version_file_content('1.0.1')
    updated_content = action.bump_version_file(content, 'patch')
    expect(updated_content).to eq(expected_content)
  end

  it 'add comment for invalid semver' do
    expect(action).to receive(:add_comment_for_invalid_semver)
    action.update_version('invalid_semver')
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
