# frozen_string_literal: true

require_relative 'action'

# Parse the command and call the action accordingly.
class Command
  attr_reader :config, :action, :options

  def initialize(config)
    @config = config
    cmd = config.payload['comment']['body']
    @action, @options = cmd.split
  end

  def call
    return unless action.start_with?('/')

    case action
    when '/version-update'
      Action.new(config).bump_version(options)
    else
      puts 'Command is not valid'
    end
  end
end
