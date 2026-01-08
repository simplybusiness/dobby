# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simplycop/version'

Gem::Specification.new do |spec|
  spec.name          = 'simplycop'
  spec.version       = Simplycop::VERSION
  spec.authors       = ['Simply Business']
  spec.email         = ['tech@simplybusiness.co.uk']
  spec.required_ruby_version = ['>= 3.2 ', '< 4.1']
  spec.license       = 'MIT'
  spec.summary       = 'Provides a single point of reference for common rubocop rules.'
  spec.description   = 'Require this gem in your application to use Simply Business common rubocop rules.'
  spec.homepage      = 'https://github.com/simplybusiness/simplycop'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_dependency 'benchmark', '~> 0.3'
  spec.add_dependency 'rubocop', '1.82.1'
  spec.add_dependency 'rubocop-ast', '1.49.0'
  spec.add_dependency 'rubocop-capybara', '2.22.1'
  spec.add_dependency 'rubocop-factory_bot', '2.28.0'
  spec.add_dependency 'rubocop-performance', '1.26.1'
  spec.add_dependency 'rubocop-rails', '2.34.3'
  spec.add_dependency 'rubocop-rake', '0.7.1'
  spec.add_dependency 'rubocop-rspec', '3.8.0'
  spec.add_dependency 'rubocop-rspec_rails', '2.32.0'
  spec.add_development_dependency 'bundler', '>= 2.2.15'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.10'
end
