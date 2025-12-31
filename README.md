# wheneverd

Wheneverd is to systemd timers what the `whenever` gem is to cron.

Tagline / repo: `git@github.com:bigcurl/wheneverd.git`

## Status

Early scaffold: gem structure + a placeholder CLI are in place; the systemd generation features are not implemented yet.

See `FEATURE_SUMMARY.md` for high-level user-visible changes, and `CHANGELOG.md` for versioned release notes.

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
