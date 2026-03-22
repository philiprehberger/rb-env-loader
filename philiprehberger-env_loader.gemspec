# frozen_string_literal: true

require_relative 'lib/philiprehberger/env_loader/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-env_loader'
  spec.version       = Philiprehberger::EnvLoader::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Multi-source environment variable loader with precedence and validation'
  spec.description   = 'Load environment variables from multiple .env files with configurable ' \
                       'precedence, type coercion, required key validation, default values, ' \
                       'and template generation for documentation.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-env-loader'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
