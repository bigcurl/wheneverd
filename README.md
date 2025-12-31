# wheneverd

Wheneverd is to systemd timers what the `whenever` gem is to cron.

Tagline / repo: `git@github.com:bigcurl/wheneverd.git`

## Status

Early scaffold: DSL loading, systemd rendering, and safe unit write/delete are implemented as library APIs; the CLI is still a placeholder.

See `FEATURE_SUMMARY.md` for high-level user-visible behavior, and `CHANGELOG.md` for release notes (once versioned releases begin).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "wheneverd"
```

And then execute:

```bash
bundle install
```

## Usage

```bash
wheneverd --help
```

## Development

```bash
bundle exec rake test
```

Test runs write a coverage report to `coverage/`.
