# frozen_string_literal: true

require_relative '../spec_helper'
describe Command do
  let(:config) do
    test_config = double
    allow(test_config).to receive(:payload).and_return(
      {
        'comment' => {
          'body' => body
        }
      }
    )
    test_config
  end

  describe 'initialize' do
    let(:body) { '/dobby version minor' }

    it 'sets command and option' do
      cmd = Command.new(config)
      expect(cmd.command).to eq('version')
      expect(cmd.options).to eq('minor')
    end
  end

  describe 'version' do
    context 'when valid command' do
      let(:body) { '/dobby version minor' }

      it 'bumps the version' do
        action = double
        allow(Action).to receive(:new).and_return(action)

        expect(action).to receive(:initiate_version_update).with('minor')
        Command.new(config).call
      end

      context 'when comment starts with /Dobby' do
        let(:body) { '/Dobby version patch' }

        it 'bumps the version' do
          action = double
          allow(Action).to receive(:new).and_return(action)

          expect(action).to receive(:initiate_version_update).with('patch')
          Command.new(config).call
        end
      end
    end

    context 'when invalid command' do
      let(:body) { '/dobby barney laugh' }

      it 'does not bump the version but reacts with confused emoji' do
        action = double
        allow(Action).to receive(:new).and_return(action)

        expect(action).to receive(:add_reaction).with('confused')
        expect(action).to_not receive(:initiate_version_update).with('minor')
        Command.new(config).call
      end
    end
  end
end
