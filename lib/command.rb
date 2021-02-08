# frozen_string_literal: true

require_relative 'action'

# Parse the command and call the action accordingly.
class Command
  attr_reader :config, :command, :options

  def initialize(config)
    @config = config
    cmd = config.payload['comment']['body']
    @command, @options = cmd.split
  end

  def call
    return unless command.start_with?('/')

    action = Action.new(config)
    case command
    when '/version-update'
      action.bump_version(options)
    else
      puts 'Command is invalid'
      action.add_reaction('confused')
    end
  end
end
