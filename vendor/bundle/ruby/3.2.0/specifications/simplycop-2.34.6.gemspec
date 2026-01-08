# -*- encoding: utf-8 -*-
# stub: simplycop 2.34.6 ruby lib

Gem::Specification.new do |s|
  s.name = "simplycop".freeze
  s.version = "2.34.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Simply Business".freeze]
  s.date = "2026-01-07"
  s.description = "Require this gem in your application to use Simply Business common rubocop rules.".freeze
  s.email = ["tech@simplybusiness.co.uk".freeze]
  s.homepage = "https://github.com/simplybusiness/simplycop".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 3.2".freeze, "< 4.1".freeze])
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Provides a single point of reference for common rubocop rules.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<benchmark>.freeze, ["~> 0.3"])
  s.add_runtime_dependency(%q<rubocop>.freeze, ["= 1.82.1"])
  s.add_runtime_dependency(%q<rubocop-ast>.freeze, ["= 1.49.0"])
  s.add_runtime_dependency(%q<rubocop-capybara>.freeze, ["= 2.22.1"])
  s.add_runtime_dependency(%q<rubocop-factory_bot>.freeze, ["= 2.28.0"])
  s.add_runtime_dependency(%q<rubocop-performance>.freeze, ["= 1.26.1"])
  s.add_runtime_dependency(%q<rubocop-rails>.freeze, ["= 2.34.3"])
  s.add_runtime_dependency(%q<rubocop-rake>.freeze, ["= 0.7.1"])
  s.add_runtime_dependency(%q<rubocop-rspec>.freeze, ["= 3.8.0"])
  s.add_runtime_dependency(%q<rubocop-rspec_rails>.freeze, ["= 2.32.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2.2.15"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
end
