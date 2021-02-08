# frozen_string_literal: true

require_relative '../spec_helper'
# rubocop:disable Metrics/BlockLength
describe Command do
  let(:config) do
    OpenStruct.new(
      payload: {
        'comment' => {
          'body' => body
        }
      }
    )
  end

  describe 'version-update' do
    context 'for valid command' do
      let(:body) { '/version-update minor' }
      it 'bumps the version' do
        action = double
        allow(Action).to receive(:new).and_return(action)

        expect(action).to receive(:bump_version).with('minor')
        Command.new(config).call
      end
    end

    context 'for invalid command' do
      let(:body) { '/some_invalid_command option' }

      it 'do not bump the version and add confused reaction' do
        action = double
        allow(Action).to receive(:new).and_return(action)

        expect(action).to receive(:add_reaction).with('confused')
        expect(action).to_not receive(:bump_version).with('minor')
        Command.new(config).call
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
