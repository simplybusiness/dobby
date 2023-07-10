# frozen_string_literal: true

require_relative 'action'

# Parse the command and call the action accordingly.
class Command
  attr_reader :config, :command, :options

  COMMAND_PREFIX = '/dobby'

  def initialize(config)
    @config = config
    comment = config.payload['comment']['body'].strip.downcase
    error_msg = "Comment must be start with #{COMMAND_PREFIX}"
    puts "::error title=Arguement Error::#{error_msg}"
    raise ArgumentError, error_msg unless comment.start_with?(COMMAND_PREFIX)

    cmd = comment.delete_prefix(COMMAND_PREFIX)
    @command, @options = cmd.split
  end

  def call
    action = Action.new(config)
    case command
    when 'version'
      action.initiate_version_update(options)
    else
      puts "::error title=Unknown command::The command #{command} is not valid"
      action.add_reaction('confused')
    end
  end
end
