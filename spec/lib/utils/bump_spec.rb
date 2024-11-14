require 'spec_helper'
require 'utils/bump'

RSpec.describe Bump do
  let(:config) { double('config') }
  let(:payload) { { 'repository' => { 'full_name' => 'owner/repo' }, 'issue' => { 'number' => 123 } } }
  let(:client) { double('client') }
  let(:version_file_path) { 'path/to/version/file' }
  let(:other_version_file_paths) { ['path/to/other/version/file'] }
  let(:base_content) { double('content') }
  let(:head_content) { double('content') }
  let(:commit) { double('commit') }

  before do
    allow(config).to receive_messages(
      payload: payload, client: client, version_file_path: version_file_path,
      other_version_file_paths: other_version_file_paths
    )
    allow(Content).to receive(:new).with(
      config: config, ref: 'base_branch',
      path: anything
    ).and_return(base_content)
    allow(Content).to receive(:new).with(
      config: config, ref: 'head_branch',
      path: anything
    ).and_return(head_content)

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
      expect(version.match(Bump::VERSION_SETTING)[0]).to eq(version)
    end

    it 'matches a lowercase, underscored, quote-marked, equal separated semver' do
      version = '__version__ = "1.0.0"'
      expect(version.match(Bump::VERSION_SETTING)[0]).to eq(version)
    end
  end

  describe '#bump_everything' do
    it 'bumps the version and commits the changes' do
      allow(head_content).to receive(:content).and_return('version: 1.0.0')
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

    it 'skips updating if the desired version bump is already present' do
      allow(head_content).to receive(:content).and_return('version: 1.0.1')
      allow(base_content).to receive(:content).and_return('version: 1.0.0')

      bump = Bump.new(config, 'patch')
      expect(commit).not_to receive(:multiple_files)
      expect do
        bump.bump_everything
      end.to output(
        "::notice title=Nothing to update::The desired version bump is already present for: " \
        "#{other_version_file_paths[0]}\n" \
        "::notice title=Nothing to update::The desired version bump is already present for: " \
        "#{version_file_path}\n"
      ).to_stdout
    end

    it 'retains modified version file content' do
      allow(head_content).to receive(:content).and_return('version: 1.0.0 extra stuff here')
      allow(base_content).to receive(:content).and_return('version: 1.0.0')

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
      allow(head_content).to receive(:content).and_return('__version__ = "1.0.0"')
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
