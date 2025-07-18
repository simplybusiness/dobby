# frozen_string_literal: true

require_relative 'action'

# Parse the command and call the action accordingly.
class Command
  attr_reader :config, :command, :options

  COMMAND_PREFIX = '/dobby'

  def initialize(config)
    @config = config
    @message = "## Dobby bumping the version\n"
    comment = config.payload['comment']['body'].strip.downcase
    init_error unless comment.start_with?(COMMAND_PREFIX)

    cmd = comment.delete_prefix(COMMAND_PREFIX).strip
    @command, @options, @extra = cmd.split(/\s+/, 3)
    puts "::debug::Command: #{@command}, Options: #{@options}, Extra: #{@extra}"
  end

  def call
    action = Action.new(config)
    if command == 'version'
      @message += action.initiate_version_update(options).to_s
    else
      @message += error_msg
      puts "::error title=Unknown command::The command #{command} is not valid"
      action.add_reaction('confused')
    end
    File.open(ENV.fetch('GITHUB_STEP_SUMMARY', nil), 'w') { |file| file.puts @message }
  end

  private

  def error_msg
    "### :boom: Error:boom:\n\n" \
      "The command #{command} is not valid so failing the action. " \
      "Expecting a command of 'version'."
  end

  def init_error
    msg = "Comment must start with #{COMMAND_PREFIX}"
    puts "::error title=Argument Error::#{msg}"
    @message += "### :boom: Error:boom:\n\n The comment must start with #{COMMAND_PREFIX} so failing the action."
    raise ArgumentError, msg
  end
end
