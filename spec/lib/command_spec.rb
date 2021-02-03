# frozen_string_literal: true

require_relative '../spec_helper'

describe Command do
  context 'version-update command' do
    it 'raises exception for invalid command' do
      expect do
        Command.new('something else').call
      end.to raise_exception Command::InvalidCommandError
    end

    it 'raises exception for command not allowed' do
      expect do
        Command.new('/somecommand option').call
      end.to raise_exception Command::InvalidCommandError
    end

    it 'calls the update action' do
      action = double
      allow(Action).to receive(:new).and_return(action)
      expect(action).to receive(:update_version).with('minor')
      Command.new('/version-update minor').call
    end
  end
end
