# frozen_string_literal: true

require 'ostruct'
require_relative '../spec_helper'

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

  it 'increment the minor version' do
    mock_version_response('1.0.0', 'master')
    res = action.update_version('minor'))
    updated_version = Gem::Version.new('1.1.0')
    expect(res.version).to eq(updated_version)
  end

  private

  def mock_version_response(version, branch)
    content = {
      'content' => Base64.encode64(%(
        module TestRepo
          VERSION='#{version}'
        end
      ))
    }
    allow(client).to receive(:contents)
      .with('simplybusiness/test', path: 'lib/version.rb', query: { ref: branch })
      .and_return(content)
  end
end
