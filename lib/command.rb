# frozen_string_literal: true

require 'action'

# Parse the command and call the action accordingly.
class Command
  attr_reader :action, :options

  class InvalidCommandError < ArgumentError; end

  def initialize(cmd)
    @action, @options = parse(cmd)
  end

  def parse(cmd)
    raise InvalidCommandError unless cmd.start_with?('/version-update')

    cmd.split(' ')
  end

  def call
    case action
    when '/version-update'
      Action.new.update_version(options)
    else
      raise InvalidCommandError
    end
  end
end
