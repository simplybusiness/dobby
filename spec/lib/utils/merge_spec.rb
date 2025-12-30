require 'spec_helper'
require 'utils/merge'
require 'config'
require 'octokit'

RSpec.describe Merge do
  let(:config) { instance_double(Config) }
  let(:client) { instance_double(Octokit::Client) }
  let(:payload) do
    {
      'repository' => { 'full_name' => 'owner/repo' },
      'issue' => { 'number' => 123 }
    }
  end

  before do
    allow(config).to receive_messages(client: client, payload: payload)
    allow(client).to receive(:pull_request).with('owner/repo', 123).and_return(
      {
        'head' => { 'ref' => 'feature-branch' },
        'base' => { 'ref' => 'main' }
      }
    )
  end

  describe '#merge_base_into_head' do
    it 'successfully merges base branch into head branch' do
      expect(client).to receive(:merge).with(
        'owner/repo',
        'feature-branch',
        'main',
        commit_message: 'Merge main into feature-branch'
      ).and_return({ 'sha' => 'abc123' })

      merge = Merge.new(config)
      result = merge.merge_base_into_head

      expect(result[:success]).to be true
      expect(result[:message]).to include('Successfully merged main into feature-branch')
    end

    it 'handles when branch is already up to date' do
      expect(client).to receive(:merge).with(
        'owner/repo',
        'feature-branch',
        'main',
        commit_message: 'Merge main into feature-branch'
      ).and_return(nil)

      merge = Merge.new(config)
      result = merge.merge_base_into_head

      expect(result[:success]).to be true
      expect(result[:message]).to include('already up to date')
    end

    it 'handles merge conflicts' do
      expect(client).to receive(:merge).with(
        'owner/repo',
        'feature-branch',
        'main',
        commit_message: 'Merge main into feature-branch'
      ).and_raise(Octokit::Conflict.new)

      merge = Merge.new(config)
      result = merge.merge_base_into_head

      expect(result[:success]).to be false
      expect(result[:message]).to include('merge conflict detected')
    end

    it 'handles other errors during merge' do
      expect(client).to receive(:merge).with(
        'owner/repo',
        'feature-branch',
        'main',
        commit_message: 'Merge main into feature-branch'
      ).and_raise(StandardError.new('Network error'))

      merge = Merge.new(config)
      result = merge.merge_base_into_head

      expect(result[:success]).to be false
      expect(result[:message]).to include('Network error')
    end
  end
end
