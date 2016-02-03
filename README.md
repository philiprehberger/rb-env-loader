# philiprehberger-env_loader

[![Tests](https://github.com/philiprehberger/rb-env-loader/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-env-loader/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-env_loader.svg)](https://rubygems.org/gems/philiprehberger-env_loader)
[![License](https://img.shields.io/github/license/philiprehberger/rb-env-loader)](LICENSE)

Multi-source environment variable loader with precedence and validation

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-env_loader"
```

Or install directly:

```bash
gem install philiprehberger-env_loader
```

## Usage

```ruby
require 'philiprehberger/env_loader'

Philiprehberger::EnvLoader.load('.env', '.env.local',
  required: %w[DATABASE_URL SECRET_KEY],
  defaults: { 'PORT' => '3000' },
  types: { 'PORT' => :integer, 'DEBUG' => :boolean }
)
```

### File Precedence

```ruby
# Later files override earlier ones; existing ENV always wins
Philiprehberger::EnvLoader.load('.env', '.env.local', '.env.production')
```

### Validation

```ruby
Philiprehberger::EnvLoader.validate!('DATABASE_URL', 'REDIS_URL')
# raises EnvLoader::ValidationError if any key is missing or empty
```

### Template Generation

```ruby
Philiprehberger::EnvLoader.generate_template(
  output: '.env.template',
  keys: %w[DATABASE_URL REDIS_URL SECRET_KEY PORT]
)
```

## API

| Method | Description |
|--------|-------------|
| `.load(*files, required:, types:, defaults:)` | Load variables from .env files with options |
| `.validate!(*keys)` | Raise if any keys are missing or empty in ENV |
| `.generate_template(output:, keys:)` | Generate a .env.template file |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
