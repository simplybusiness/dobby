# frozen_string_literal: true

require_relative 'lib/config'
require_relative 'lib/command'

def run
  config = Config.new
  case config.event_name
  when 'issue_comment'
    puts 'Pull request commented.'
    Command.new(config).call
  else
    puts "Event #{config.event_name} is triggered. No action called."
  end
end

run
