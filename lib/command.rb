# frozen_string_literal: true

require 'action'

# Parse the command and call the action accordingly.
class Command
  attr_reader :action, :options

  class InvalidCommandError < ArgumentError; end

  def initialize(cmd)
    @action, @options = cmd.split
  end

  def call
    case action
    when '/version-update'
      Action.new.update_version(options)
    else
      raise InvalidCommandError, 'Command is not valid'
    end
  end
end
