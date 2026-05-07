require 'spec_helper'
require 'utils/bump'
require 'utils/content'
require 'utils/commit'
require 'config'
require 'octokit'

RSpec.describe Bump do
  let(:config) { instance_double(Config) }
  let(:payload) { { 'repository' => { 'full_name' => 'owner/repo' }, 'issue' => { 'number' => 123 } } }
  let(:client) { instance_double(Octokit::Client) }
  let(:version_file_path) { 'path/to/version/file' }
  let(:other_version_file_paths) { ['path/to/other/version/file'] }
  let(:other_version_patterns) { [] }
  let(:base_content) { instance_double(Content) }
  let(:commit) { instance_double(Commit) }

  before do
    allow(config).to receive_messages(
      payload: payload, client: client, version_file_path: version_file_path,
      other_version_file_paths: other_version_file_paths, other_version_patterns: other_version_patterns
    )
    allow(Content).to receive(:new).with(
      config: config, ref: 'base_branch',
      path: anything
    ).and_return(base_content)

    allow(client).to receive(:pull_request).with(
      'owner/repo',
      123
    ).and_return({
                   'head' => { 'ref' => 'head_branch' },
                   'base' => { 'ref' => 'base_branch' }
                 })

    allow(Commit).to receive(:new).with(config).and_return(commit)
    allow(commit).to receive(:multiple_files)
  end

  describe 'VERSION_SETTING' do
    it 'matches a lowercase, colon separated semver' do
      version = 'version: 1.0.0'
      expect(Bump::VERSION_SETTING).to match(version)
    end

    it 'matches a lowercase, underscored, quote-marked, equal separated semver' do
      version = '__version__ = "1.0.0"'
      expect(Bump::VERSION_SETTING).to match(version)
    end

    it 'does not match unrelated semvers' do
      version = 'expected_ruby_version = "3.3.0"'
      expect(Bump::VERSION_SETTING).not_to match(version)
    end
  end

  describe '#bump_everything' do
    it 'bumps the version and commits the changes' do
      allow(base_content).to receive(:content).and_return('version: 1.0.0')

      bump = Bump.new(config, 'patch')
      expect(commit).to receive(:multiple_files).with(
        [
          { path: other_version_file_paths[0], mode: '100644', type: 'blob', content: 'version: 1.0.1' },
          { path: version_file_path, mode: '100644', type: 'blob', content: 'version: 1.0.1' }
        ],
        'Bump patch version'
      )
      bump.bump_everything
    end

    it 'retains modified version file content' do
      allow(base_content).to receive(:content).and_return('version: 1.0.0 extra stuff here')

      bump = Bump.new(config, 'patch')
      expect(commit).to receive(:multiple_files).with(
        [
          {
            path: other_version_file_paths[0], mode: '100644', type: 'blob',
            content: 'version: 1.0.1 extra stuff here'
          },
          { path: version_file_path, mode: '100644', type: 'blob', content: 'version: 1.0.1 extra stuff here' }
        ],
        'Bump patch version'
      )
      bump.bump_everything
    end

    it 'handles python underscored version format' do
      allow(base_content).to receive(:content).and_return('__version__ = "1.0.0"')

      bump = Bump.new(config, 'patch')
      expect(commit).to receive(:multiple_files).with(
        [
          {
            path: other_version_file_paths[0], mode: '100644', type: 'blob',
            content: '__version__ = "1.0.1"'
          },
          { path: version_file_path, mode: '100644', type: 'blob', content: '__version__ = "1.0.1"' }
        ],
        'Bump patch version'
      )
      bump.bump_everything
    end
  end
end
