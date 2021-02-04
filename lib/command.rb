# frozen_string_literal: true

require 'action'
require 'config'

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
      config = Config.new
      Action.new(config).update_version(options)
    else
      raise InvalidCommandError, 'Command is not valid'
    end
  end
end
