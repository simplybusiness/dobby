# Simplycop

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e7f30894667d4637865cc3374a5529f6)](https://app.codacy.com?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

Provides standard shared rubocop configuration for Simply Business applications. No more copying `.rubocop.yml`, no more out-of-sync configuration files. Yay!

## Table of Contents

- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Basic Setup](#basic-setup)
  - [Configuration Examples](#configuration-examples)
- [Usage](#usage)
  - [Running RuboCop](#running-rubocop)
  - [CI/CD Integration](#cicd-integration)
- [Configuration Guidelines](#configuration-guidelines)
  - [Non-Rails Projects](#non-rails-projects)
  - [Legacy Projects](#legacy-projects)
- [Security Cops](#security-cops)
- [Development](#development)
  - [Contributing Guidelines](#contributing-guidelines)
  - [Testing Configuration Changes](#testing-configuration-changes)
- [Versioning](#versioning)
- [FAQ](#faq)
- [Migration Guide](#migration-guide)

## Installation

### Prerequisites

- Ruby 3.2 or higher (including Ruby 4.0)
- Bundler
- RuboCop gem (automatically installed as a dependency)

### Basic Setup

Add this line to your application's Gemfile via bundle add:

```
bundle add 'simplycop'
```

Then install gems by executing:

    $ bundle install

Create or update your `.rubocop.yml` file with the following basic configuration:

```yaml
inherit_gem:
  simplycop: .simplycop.yml

AllCops:
  Exclude:
    - 'vendor/**/*'
    - 'db/schema.rb'
    - 'node_modules/**/*'
```

### Configuration Examples

#### Basic Rails Application with RSpec

```yaml
inherit_gem:
  simplycop:
    - .simplycop.yml
    - .simplycop_performance.yml
    - .simplycop_rails.yml
    - .simplycop_rspec.yml

AllCops:
  Exclude:
    - 'vendor/**/*'
    - 'db/schema.rb'
    - 'bin/**/*'
```

#### Rails Application with Full Test Suite

```yaml
inherit_gem:
  simplycop:
    - .simplycop.yml
    - .simplycop_performance.yml
    - .simplycop_rails.yml
    - .simplycop_rspec.yml
    - .simplycop_capybara.yml
    - .simplycop_factory_bot.yml
    - .simplycop_rspec_rails.yml

AllCops:
  Exclude:
    - 'vendor/**/*'
    - 'db/schema.rb'
    - 'bin/**/*'
```

#### Non-Rails Ruby Gem

```yaml
inherit_gem:
  simplycop: .simplycop.yml

AllCops:
  Exclude:
    - 'vendor/**/*'
```

### Available Configurations

The base `.simplycop.yml` contains cops for all the standard rubocop departments:

* Bundler
* Gemspec
* Layout
* Lint
* Metrics
* Migration
* Naming
* Security
* Style

These can also be enabled individually as follows:

```yaml
inherit_gem:
  simplycop:
    - .simplycop_<DEPARTMENT_NAME>.yml
```

**Note:** Replace `<DEPARTMENT_NAME>` with the lowercase department name (e.g., `style`, `layout`, `lint`).

### Additional Packages

For Rails projects with testing frameworks, you may want to include:
```yaml
- .simplycop_capybara.yml      # For Capybara feature tests
- .simplycop_factory_bot.yml   # For FactoryBot test factories
- .simplycop_rspec_rails.yml   # For RSpec Rails-specific cops
```

> **Important:** Capybara, FactoryBot and RSpecRails cops were previously available either via departments within `rubocop_rspec` or as packages in their own right. As of `rubocop_rspec` v3, they no longer exist as departments within `rubocop_rspec` and the packages need installing independently. If you use simplycop v1, you will still have access to some of these cops by inheriting `.simplycop_rspec`. As of simplycop v2 (which uses `rubocop_rspec` v3) you would need to inherit the packages individually.

## Usage

### Running RuboCop

Run RuboCop as you would usually do:

```bash
# Run on entire codebase
$ bundle exec rubocop

# Run with auto-correction
$ bundle exec rubocop -A

# Run only safe auto-corrections
$ bundle exec rubocop -a

# Run on specific files or directories
$ bundle exec rubocop app/ spec/

# Generate TODO configuration for existing violations
$ bundle exec rubocop --auto-gen-config
```

### CI/CD Integration

#### GitHub Actions

```yaml
name: RuboCop
on: [push, pull_request]
jobs:
  rubocop:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec rubocop
```

#### Semaphore CI

```yaml
version: v1.0
name: RuboCop
agent:
  machine:
    type: f1-standard-2
    os_image: ubuntu2204

blocks:
  - name: "RuboCop"
    task:
      jobs:
        - name: Run RuboCop
          commands:
            - checkout
            - cache restore
            - bundle install --deployment --path vendor/bundle
            - cache store
            - bundle exec rubocop
      prologue:
        commands:
          - sem-version ruby 3.2
```

## Configuration Guidelines

### Legacy Projects

When adding RuboCop and simplycop to a legacy project, you might want to initially disable some of the rules. Consider this approach:

1. **Start with basic cops**: Enable only `Style`, `Layout`, and `Lint` departments initially
2. **Generate TODO configuration**: Use `--auto-gen-config` to create a `.rubocop_todo.yml` for existing violations
3. **Gradual migration**: Enable more departments over time as you clean up the codebase
4. **Team agreement**: Ensure the team agrees on the migration timeline

Example for legacy projects:

```yaml
inherit_gem:
  simplycop:
    - .simplycop_layout.yml
    - .simplycop_lint.yml
    - .simplycop_style.yml

AllCops:
  Exclude:
    - 'vendor/**/*'
    - 'legacy_code/**/*'  # Exclude problematic areas initially
  NewCops: disable   # Don't enable new cops automatically
```

## Development

### Contributing Guidelines

To change a setting for simplycop, simply edit the relevant `.yml` file with the configuration changes you wish to make. The aim is to choose a sensible configuration for all new cops as they are added in package updates.

RuboCop is well established enough that most new cops are for niche cases. The default assumption is therefore that they will provide a small code quality benefit without major disruption to the codebase and can safely be enabled.

However, this is not always the case. Always check the notes on the cop to understand the reasoning behind it, paying particular attention to any warnings and exceptions listed.

#### Useful References

- [Base RuboCop](https://docs.rubocop.org/rubocop/cops.html)
- [RuboCop Capybara](https://docs.rubocop.org/rubocop-capybara/cops.html)
- [RuboCop Factory Bot](https://docs.rubocop.org/rubocop-factory_bot/cops.html)
- [RuboCop Performance](https://docs.rubocop.org/rubocop-performance/cops.html)
- [RuboCop Rails](https://docs.rubocop.org/rubocop-rails/cops.html)
- [RuboCop RSpec](https://docs.rubocop.org/rubocop-rspec/cops.html)
- [RuboCop RSpec Rails](https://docs.rubocop.org/rubocop-rspec_rails/cops.html)

#### When to Keep a Cop Disabled

Consider keeping the cop disabled (or selecting a sensible config option) if any of the following apply:

- The cop is disabled by default in RuboCop (Note: All new cops are set to pending until the next major RuboCop version)
- The cop is listed as not safe in RuboCop. Read the notes to find out why
- It is known that a large part of the SB codebase will systematically break a rule. Use smaller, newer repos as your benchmark for this. Chopin and Rater will have violations for most new rules, so do not disable a rule on that basis alone if it will bring benefit across the wider codebase

#### Decision-Making Guidelines

- Lean towards enabling rules if there are clear performance and/or clarity benefits
- Avoid setting config or enablement based on personal stylistic preference. If a team has a particularly strong stylistic preference on, say [explicit return of nil](https://docs.rubocop.org/rubocop/cops_style.html#stylereturnnil), this can be overridden at a repo level
- Default maximums for metrics cops are hard to meet and regularly violated. For that reason, they are mostly overridden or set as 'to-dos' within individual repos. There will be value in reducing violation of these over time, but centralized maximums have not yet been discussed or set

If in doubt, discuss in `#technical-excellence-community` or `#tech` for guidance and a wider range of opinion.

### Testing Configuration Changes

Before submitting changes to simplycop configurations:

1. **Test locally**: Apply your changes to a sample project and run RuboCop
2. **Check multiple projects**: Test on both new and legacy codebases if possible
3. **Review impact**: Consider how many violations the change might introduce
4. **Document rationale**: Include reasoning for the change in your PR description

Example testing workflow:

```bash
# In a test project
echo "inherit_gem:\n  simplycop: .simplycop.yml" > .rubocop.yml
bundle add simplycop --path="/path/to/your/local/simplycop"
bundle exec rubocop --dry-run
```

### Versioning

#### Automatic Versioning

When updating simplycop, you can use [Dobby](https://github.com/simplybusiness/dobby) in your PR comments to increment the version number. Try to stick to the following versioning principles

- MAJOR: For breaking changes (e.g in [v2.0](https://github.com/simplybusiness/simplycop/releases/tag/2.0.0) several rubocop departments were split out into separate packages)
- MINOR: For rule enablements, disablements and config changes (i.e. changes that may cause previously passing rubocop runs to fail)
- PATCH: For updates that do not touch config (e.g. individual rubocop package bumps which typically fix false positives/negatives or other bugs, doc changes)

#### Manual Versioning

If you prefer to manually version, you can do so by editing the `lib/simplycop/version.rb` file and updating the `VERSION` line and updating the `catalog-info.yaml` file with the new version number for the annotation `rubygems.org/current-version`.

## FAQ

### Common Questions

**Q: Can I override specific cops in my project?**
A: Yes, you can override any cop configuration in your local `.rubocop.yml` file. Your local configuration takes precedence over inherited configurations.

**Q: How do I handle RuboCop violations in legacy code?**
A: Use `bundle exec rubocop --auto-gen-config` to generate a `.rubocop_todo.yml` file that disables existing violations. Then gradually address violations over time.

**Q: What's the difference between simplycop v1 and v2?**
A: v2 uses RuboCop RSpec v3, which splits Capybara, FactoryBot, and RSpecRails cops into separate packages. You'll need to explicitly include these configurations if you use them.

**Q: Can I use simplycop with other RuboCop configurations?**
A: Yes, you can inherit from multiple sources. List simplycop first to establish the base, then add other configurations.

**Q: How often is simplycop updated?**
A: Simplycop is updated regularly to include new RuboCop cops and configuration improvements. Check the [releases page](https://github.com/simplybusiness/simplycop/releases) for updates.

**Q: What if a new cop causes too many violations?**
A: New cops are carefully evaluated before being enabled. If you encounter issues, discuss with the team in `#technical-excellence-community` or create an issue on the simplycop repository.

### Troubleshooting

**RuboCop exits with "undefined method" errors:**
- Ensure you're using compatible versions of RuboCop and simplycop
- Try running `bundle update` to update dependencies

**Unexpected violations after updating simplycop:**
- Check the changelog for new enabled cops
- Use `--auto-gen-config` to temporarily disable new violations while you address them

**Performance issues with large codebases:**
- Use `.rubocop.yml` exclude patterns to skip large generated files
- Consider running RuboCop on specific directories during development

## Migration Guide

### From Standard RuboCop Configuration

If you're currently using a custom `.rubocop.yml` file:

1. **Back up your current configuration**:
   ```bash
   cp .rubocop.yml .rubocop.yml.backup
   ```

2. **Create a new minimal configuration**:
   ```yaml
   inherit_gem:
     simplycop: .simplycop.yml

   AllCops:
     Exclude:
       - 'vendor/**/*'
   ```

3. **Add your project-specific overrides**:
   - Review your backup configuration
   - Add any project-specific cop configurations to your new `.rubocop.yml`
   - Test thoroughly before committing

### From Other Shared Configurations

If you're migrating from another shared RuboCop configuration:

1. **Identify differences**: Compare your current configuration with simplycop's defaults
2. **Plan the migration**: Decide whether to adopt simplycop's settings or override them
3. **Test incrementally**: Apply changes in small batches to understand the impact
4. **Update CI/CD**: Ensure your continuous integration tools use the new configuration

---

For more information, visit the [simplycop repository](https://github.com/simplybusiness/simplycop) or reach out to the team in `#technical-excellence-community`.
