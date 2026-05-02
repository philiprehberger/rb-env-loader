# philiprehberger-env_loader

[![Tests](https://github.com/philiprehberger/rb-env-loader/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-env-loader/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-env_loader.svg)](https://rubygems.org/gems/philiprehberger-env_loader)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-env-loader)](https://github.com/philiprehberger/rb-env-loader/commits/main)

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
require "philiprehberger/env_loader"

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

### Prefix Filtering

```ruby
require "philiprehberger/env_loader"

# Only load APP_* variables
vars = Philiprehberger::EnvLoader.load(".env", prefix: "APP_")
vars["APP_HOST"]  # => "localhost"

# Strip the prefix from keys
vars = Philiprehberger::EnvLoader.load(".env", prefix: "APP_", strip_prefix: true)
vars["HOST"]  # => "localhost"
```

### Template Generation

```ruby
Philiprehberger::EnvLoader.generate_template(
  output: '.env.template',
  keys: %w[DATABASE_URL REDIS_URL SECRET_KEY PORT]
)
```

### Parse from a String

Parse `.env`-formatted text without reading from disk and without touching ENV:

```ruby
content = <<~ENV
  APP_HOST=localhost
  APP_PORT=3000
  # comments and blank lines are ignored
ENV

Philiprehberger::EnvLoader.parse(content)
# => { "APP_HOST" => "localhost", "APP_PORT" => "3000" }
```

## API

| Method | Description |
|--------|-------------|
| `.load(*files, required:, types:, defaults:, prefix:, strip_prefix:)` | Load variables from .env files with options |
| `.validate!(*keys)` | Raise if any keys are missing or empty in ENV |
| `.generate_template(output:, keys:)` | Generate a .env.template file |
| `.parse(content)` | Parse `.env`-formatted content from a string into a hash without touching ENV |
| `EnvLoader::Error` | Base error class for all gem errors |
| `EnvLoader::ValidationError` | Raised when required keys are missing or empty |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-env-loader)

🐛 [Report issues](https://github.com/philiprehberger/rb-env-loader/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-env-loader/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
