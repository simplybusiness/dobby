require 'spec_helper'
require 'utils/bump'

RSpec.describe Bump do
  let(:config) { double('config') }
  let(:level) { 'patch' }
  let(:payload) { { 'repository' => { 'full_name' => 'owner/repo' }, 'issue' => { 'number' => 123 } } }
  let(:client) { double('client') }
  let(:version_file_path) { 'path/to/version/file' }
  let(:other_version_file_paths) { ['path/to/other/version/file'] }
  let(:content) { double('content') }
  let(:commit) { double('commit') }

  before do
    allow(config).to receive(:payload).and_return(payload)
    allow(config).to receive(:client).and_return(client)
    allow(config).to receive(:version_file_path).and_return(version_file_path)
    allow(config).to receive(:other_version_file_paths).and_return(other_version_file_paths)
    allow(Content).to receive(:new).with(config: config, ref: 'base_branch', path: version_file_path).and_return(content)
    allow(Content).to receive(:new).with(config: config, ref: 'head_branch', path: version_file_path).and_return(content)
    allow(content).to receive(:content).and_return('version: 1.0.0')
    allow(content).to receive(:content=)
    allow(client).to receive(:pull_request).with('owner/repo', 123).and_return({ 'head' => { 'ref' => 'head_branch' }, 'base' => { 'ref' => 'base_branch' } })
    allow(Semantic::Version).to receive(:new).and_return(double('version'))
    allow(double('version')).to receive(:increment!)
    allow(Commit).to receive(:new).with(config).and_return(commit)
    allow(commit).to receive(:multiple_files)
  end

  describe '#bump_everything' do
    it 'bumps the version and commits the changes' do
      bump = Bump.new(config, level)
      expect(Content).to receive(:new).with(config: config, ref: 'base_branch', path: version_file_path).and_return(content).ordered
      expect(Content).to receive(:new).with(config: config, ref: 'head_branch', path: version_file_path).and_return(content).ordered
      expect(content).to receive(:content).and_return('version: 1.0.0').ordered
      expect(content).to receive(:content=).with('version: 1.0.1').ordered
      expect(commit).to receive(:multiple_files).with([{ path: version_file_path, mode: '100644', type: 'blob', content: 'version: 1.0.1' }], 'Bump patch version')
      bump.bump_everything
    end

    it 'skips updating if the desired version bump is already present' do
      bump = Bump.new(config, level)
      expect(Content).to receive(:new).with(config: config, ref: 'base_branch', path: version_file_path).and_return(content).ordered
      expect(Content).to receive(:new).with(config: config, ref: 'head_branch', path: version_file_path).and_return(content).ordered
      expect(content).to receive(:content).and_return('version: 1.0.1').ordered
      expect(commit).not_to receive(:multiple_files)
      expect { bump.bump_everything }.to output("::notice title=Nothing to update::The desired version bump is already present for: path/to/version/file\n").to_stdout
    end
  end
end
