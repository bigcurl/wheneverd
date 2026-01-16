# wheneverd

Wheneverd is to systemd timers what the [`whenever` gem](https://github.com/javan/whenever) is to cron.

## Status

Pre-1.0, but working end-to-end for systemd user timers on Linux:

- Loads a Ruby schedule DSL file (default: `config/schedule.rb`).
- Renders systemd `.service`/`.timer` units (interval, calendar, and 5-field cron schedules).
- Writes, diffs, shows, and deletes generated unit files (default: `~/.config/systemd/user`).
- Enables/starts/stops/disables/restarts timers via `systemctl --user`.
- Validates `OnCalendar=` values with `systemd-analyze` (optional unit verification).
- Manages lingering via `loginctl` (so timers can run while logged out).

Non-goals / not yet implemented:

- System-level units (`/etc/systemd/system`) / `systemctl` without `--user`.
- Non-systemd schedulers (cron, launchd, etc).
- Non-Linux platforms (no Windows/macOS support).

Expect the CLI and generated unit details to change until 1.0.

See `FEATURE_SUMMARY.md` for user-visible behavior, and `CHANGELOG.md` for release notes.

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
wheneverd status
wheneverd diff
wheneverd validate
wheneverd write
wheneverd delete
wheneverd activate
wheneverd deactivate
wheneverd reload
wheneverd current
wheneverd linger
```

Use `wheneverd init` to create a starter `config/schedule.rb` template (including examples for `command` and `shell`).

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

### Deploy a simple schedule (copy/paste)

From your project root (the default identifier is the current directory name):

```bash
# Install (skip if already in your Gemfile)
bundle add wheneverd
bundle install

# Write a schedule that appends a timestamp to ~/.cache/wheneverd-demo.log every minute
mkdir -p config
cat > config/schedule.rb <<'RUBY'
# frozen_string_literal: true

every "1m" do
  shell "mkdir -p ~/.cache && date >> ~/.cache/wheneverd-demo.log"
end
RUBY

# Preview, write units, and enable/start the timer(s)
bundle exec wheneverd show
bundle exec wheneverd validate
bundle exec wheneverd write
bundle exec wheneverd activate

# Verify it’s installed and running
bundle exec wheneverd status
tail -n 5 ~/.cache/wheneverd-demo.log

# Stop/disable timers and remove generated unit files
bundle exec wheneverd deactivate
bundle exec wheneverd delete
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

### User timers and lingering (`loginctl enable-linger`)

By default, `wheneverd` uses *user* systemd units (`systemctl --user`). On many systems, the per-user systemd instance
only runs while you are logged in. If you want timers to run after logout (or on boot without an interactive login),
enable lingering for your user:

```bash
wheneverd linger enable
```

This runs `loginctl enable-linger "$USER"` under the hood. If you see “Access denied”, your system may require admin
privileges (polkit policy); try:

```bash
sudo loginctl enable-linger "$USER"
```

Check whether lingering is enabled:

```bash
wheneverd linger status
```

To disable it later:

```bash
wheneverd linger disable
```

## Syntax

Schedules are defined in a Ruby file (default: `config/schedule.rb`) and evaluated in a dedicated DSL context.

Note: schedule files are executed as Ruby. Do not run untrusted schedule code.

The core shape is:

```ruby
every(period, at: nil) do
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

`command(...)` appends a oneshot `ExecStart=` job.

Accepted forms:

- `command("...")` (String): inserted into `ExecStart=` as-is (after stripping surrounding whitespace).
- `command(["bin", "arg1", "arg2"])` (argv Array): formatted/escaped into a systemd-compatible `ExecStart=` string.

If you need shell features (pipes, redirects, globbing, env var expansion), either wrap it yourself, or use `shell`:

```ruby
command "/bin/bash -lc 'echo hello | sed -e s/hello/hi/'"
command ["/bin/bash", "-lc", "echo hello | sed -e s/hello/hi/"]
```

### `shell`

`shell("...")` is a convenience helper for the common `/bin/bash -lc` pattern:

```ruby
shell "echo hello | sed -e s/hello/hi/"
```

### `every` periods

Supported `period` forms:

- Interval strings: `"<n>s|m|h|d|w"` (examples: `"5m"`, `"1h"`) for monotonic timers (`OnActiveSec=` + `OnUnitActiveSec=`).
- Duration objects: `1.second`, `1.minute`, `1.hour`, `1.day`, `1.week` (and plurals), using the same interval semantics.
- Symbol shortcuts:
  - `:hour`, `:day`, `:month`, `:year` (calendar schedules, mapped to `hourly`, `daily`, `monthly`, `yearly`)
- `:reboot` (boot trigger, mapped to `OnBootSec=1`).
- Day selectors: `:monday..:sunday`, plus `:weekday` and `:weekend` (calendar schedules; multiple day symbols supported).
- Cron strings (5 fields), like `"0 0 27-31 * *"` (calendar schedules).

Notes:

- Interval/duration schedules are monotonic (run relative to last execution), while calendar schedules are wall-clock
  based. In particular, `every 1.day` is monotonic, but `every :day` is calendar-based.
- `at:` is only supported with calendar periods. `every 1.day, at: ...` is supported as a convenience and is treated
  as a daily calendar trigger.
- `at:` is not supported with `every :reboot`.

### `at:` times

`at:` may be a single string or an array of strings. Times are normalized at render time.

`at:` is not supported for interval strings (like `"5m"`) or cron strings.

Accepted examples:

- `"4:30 am"`, `"6:00 pm"`, `"12pm"`
- `"00:15"` (24h)

### Cron strings

Cron translation supports standard 5-field crontab strings (`minute hour day-of-month month day-of-week`), including:

- Wildcards, lists, ranges, and steps (`*`, `1,2,3`, `1-5`, `*/15`, `1-10/2`)
- Month and day-of-week names (`Jan`, `Mon`)
- Cron day-of-month vs day-of-week OR semantics (may expand into multiple `OnCalendar=` lines)

Unsupported cron patterns raise an error at render time (e.g. non-5-field strings, `@daily`, `L`, `W`, `#`, `?`).

## CLI

Defaults:

- schedule path: `config/schedule.rb` (override with `--schedule PATH`)
- identifier: current directory name (override with `--identifier NAME`)
- unit dir: `~/.config/systemd/user` (override with `--unit-dir PATH`)

Notes:

- Errors use Clamp-style `ERROR: ...` formatting; add `--verbose` to include error details.
- `wheneverd delete` / `wheneverd current` only operate on units matching the identifier *and* the generated marker line.
- Identifiers are sanitized for use in unit file names (non-alphanumeric characters become `-`).
- Unit basenames include a stable ID derived from the job’s trigger + command (reordering schedule blocks won’t rename units).
- `wheneverd write` / `wheneverd reload` prune previously generated units for the identifier by default (use `--no-prune` to keep old units around).
- `--unit-dir` controls where unit files are written/read/deleted; `activate`/`deactivate` use systemd’s unit search path.
- `wheneverd diff` returns exit status `0` when no differences are found, and `1` when differences are found.

Commands:

- `wheneverd init [--schedule PATH] [--force]` writes a template schedule file.
- `wheneverd show [--schedule PATH] [--identifier NAME]` prints rendered units to stdout.
- `wheneverd status [--identifier NAME] [--unit-dir PATH]` prints `systemctl --user list-timers` and `systemctl --user status` for installed timers.
- `wheneverd diff [--schedule PATH] [--identifier NAME] [--unit-dir PATH]` diffs rendered units vs unit files on disk.
- `wheneverd validate [--schedule PATH] [--identifier NAME] [--verify]` validates rendered `OnCalendar=` values via `systemd-analyze calendar` (and with `--verify`, runs `systemd-analyze --user verify` on temporary unit files).
- `wheneverd write [--schedule PATH] [--identifier NAME] [--unit-dir PATH] [--dry-run] [--[no-]prune]` writes units to disk (or prints paths in `--dry-run` mode).
- `wheneverd delete [--identifier NAME] [--unit-dir PATH] [--dry-run]` deletes previously generated units for the identifier.
- `wheneverd activate [--schedule PATH] [--identifier NAME]` runs `systemctl --user daemon-reload` and enables/starts the timers.
- `wheneverd deactivate [--schedule PATH] [--identifier NAME]` stops and disables the timers.
- `wheneverd reload [--schedule PATH] [--identifier NAME] [--unit-dir PATH] [--[no-]prune]` writes units, reloads systemd, and restarts timers.
- `wheneverd current [--identifier NAME] [--unit-dir PATH]` prints the currently installed unit file contents from disk.
- `wheneverd linger [--user NAME] [enable|disable|status]` manages lingering via `loginctl` (`status` is the default).

## Development

```bash
bundle install

# Run the CLI from this repo:
bundle exec exe/wheneverd --help

bundle exec rake test
bundle exec rake ci
bundle exec rake yard

# Also supported after `bundle install`:
rake ci
rake yard
```

Test runs write a coverage report to `coverage/`.

YARD docs are written to `doc/` (and `.yardoc/`).
