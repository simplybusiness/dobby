# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/../lib/*.rb"].each { |f| require_relative f }
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  config.include Helpers::ResponseHelper
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
