# frozen_string_literal: true

require_relative 'action'

# Parse the command and call the action accordingly.
class Command
  attr_reader :config, :command, :options

  COMMAND_PREFIX = '/dobby'

  def initialize(config)
    @config = config
    comment = config.payload['comment']['body'].strip.downcase
    unless comment.start_with?(COMMAND_PREFIX)
      error_msg = "Comment must start with #{COMMAND_PREFIX}"
      puts "::error title=Argument Error::#{error_msg}"
      raise ArgumentError, error_msg
    end

    cmd = comment.delete_prefix(COMMAND_PREFIX).strip
    @command, @options, @extra = cmd.split(/\s+/, 3)
    puts "::debug::Command: #{@command}, Options: #{@options}, Extra: #{@extra}"
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
