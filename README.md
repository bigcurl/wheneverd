# wheneverd

Wheneverd is to systemd timers what the [`whenever` gem](https://github.com/javan/whenever) is to cron.

Tagline / repo: `git@github.com:bigcurl/wheneverd.git`

## Status

Working end-to-end: schedule DSL loading, systemd unit rendering, and safe unit write/list/delete are implemented, along with a CLI for `init`, `show`, `write`, `delete`, `activate`, `deactivate`, `reload`, and `current`.

Known limitations: cron translation supports a small subset; `roles:` is accepted but not used for filtering yet.

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
wheneverd init
wheneverd show
wheneverd write
wheneverd delete
wheneverd activate
wheneverd deactivate
wheneverd reload
wheneverd current
```

### Minimal `config/schedule.rb` example

```ruby
# frozen_string_literal: true

every "5m" do
  command "echo hello"
end

every 1.day, at: "4:30 am" do
  command "echo four_thirty"
end
```

Preview the generated units:

```bash
wheneverd show
```

### Activating / deactivating (systemd)

After `wheneverd write`, use `wheneverd activate` to enable + start the generated timer units (by default, user units
in `~/.config/systemd/user`):

```bash
wheneverd activate
```

Deactivate a timer:

```bash
wheneverd deactivate
```

After changing your schedule, rewrite units and restart the timer(s) to pick up changes:

```bash
wheneverd reload
```

## Syntax

Schedules are defined in a Ruby file (default: `config/schedule.rb`) and evaluated in a dedicated DSL context.

Note: schedule files are executed as Ruby. Do not run untrusted schedule code.

The core shape is:

```ruby
every(period, at: nil, roles: nil) do
  command "echo hello"
end
```

For calendar schedules, you can also pass multiple period symbols (or an array) to run the same jobs on multiple days:

```ruby
every :tuesday, :wednesday, at: "12pm" do
  command "echo midweek"
end
```

### `command`

`command("...")` appends a oneshot `ExecStart=` job. Commands must be non-empty strings.

The command string is inserted into `ExecStart=` as-is (no shell wrapping). If you need shell features
(pipes, redirects, globbing, env var expansion), wrap it yourself, for example:

```ruby
command "/bin/bash -lc 'echo hello | sed -e s/hello/hi/'"
```

### `every` periods

Supported `period` forms:

- Interval strings: `"<n>s|m|h|d|w"` (examples: `"5m"`, `"1h"`) for monotonic timers (`OnUnitActiveSec=`).
- Duration objects: `1.second`, `1.minute`, `1.hour`, `1.day`, `1.week` (and plurals), using the same interval semantics.
- Symbol shortcuts:
  - `:hour`, `:day`, `:month`, `:year` (calendar schedules, mapped to `hourly`, `daily`, `monthly`, `yearly`)
- Day selectors: `:monday..:sunday`, plus `:weekday` and `:weekend` (calendar schedules; multiple day symbols supported).
- Cron strings (5 fields), like `"0 0 27-31 * *"` (calendar schedules).

Notes:

- Interval/duration schedules are monotonic (run relative to last execution), while calendar schedules are wall-clock
  based. In particular, `every 1.day` is monotonic, but `every :day` is calendar-based.
- `at:` is only supported with calendar periods. `every 1.day, at: ...` is supported as a convenience and is treated
  as a daily calendar trigger.

### `at:` times

`at:` may be a single string or an array of strings. Times are normalized at render time.

`at:` is not supported for interval strings (like `"5m"`) or cron strings.

Accepted examples:

- `"4:30 am"`, `"6:00 pm"`, `"12pm"`
- `"00:15"` (24h)

### Cron limitations

Cron translation supports a limited subset:

- minute: number (`0..59`)
- hour: number (`0..23`)
- day-of-month: `*`, a number (`1..31`), or a simple range (`27-31`)
- month: must be `*`
- day-of-week: must be `*`

Unsupported cron patterns raise an error at render time.

### `roles:`

`roles:` is accepted and stored on entries, but is ignored in v1 (no role-based filtering yet).

## CLI

Defaults:

- schedule path: `config/schedule.rb` (override with `--schedule PATH`)
- identifier: current directory name (override with `--identifier NAME`)
- unit dir: `~/.config/systemd/user` (override with `--unit-dir PATH`)

Notes:

- Errors use Clamp-style `ERROR: ...` formatting; add `--verbose` to include error details.
- `wheneverd delete` / `wheneverd current` only operate on units matching the identifier *and* the generated marker line.
- Identifiers are sanitized for use in unit file names (non-alphanumeric characters become `-`).

Commands:

- `wheneverd init [--schedule PATH] [--force]` writes a template schedule file.
- `wheneverd show [--schedule PATH] [--identifier NAME]` prints rendered units to stdout.
- `wheneverd write [--dry-run] [--unit-dir PATH]` writes units to disk (or prints paths in `--dry-run` mode).
- `wheneverd delete [--dry-run] [--unit-dir PATH]` deletes previously generated units for the identifier.
- `wheneverd activate [--schedule PATH] [--identifier NAME]` runs `systemctl --user daemon-reload` and enables/starts the timers.
- `wheneverd deactivate [--schedule PATH] [--identifier NAME]` stops and disables the timers.
- `wheneverd reload [--schedule PATH] [--identifier NAME] [--unit-dir PATH]` writes units, reloads systemd, and restarts timers.
- `wheneverd current [--identifier NAME] [--unit-dir PATH]` prints the currently installed unit file contents from disk.

## Development

```bash
bundle install
bundle exec rake test
bundle exec rake ci
bundle exec rake yard

# Also supported after `bundle install`:
rake ci
rake yard
```

Test runs write a coverage report to `coverage/`.

YARD docs are written to `doc/` (and `.yardoc/`).
