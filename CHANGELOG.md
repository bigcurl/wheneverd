# Changelog

This project keeps all changes in `## Unreleased` until they are released.
On release, entries are moved into `## x.y.z` sections that match the gem version.

## Unreleased

- Schedule DSL: `command` accepts argv arrays, and adds a `shell` helper for `/bin/bash -lc`.

## 0.2.1

- Removes an unused filtering metadata keyword argument from the schedule DSL.

## 0.2.0

- Adds `wheneverd linger enable|disable|status` for managing systemd user lingering via `loginctl`.

## 0.1.0

- Provides a Clamp-based `wheneverd` CLI with `--help`, `--version`, and `--verbose` (usage errors in `ERROR: ...` format).
- Adds core domain objects and helpers for building schedules (interval parsing, durations, triggers, entries, jobs).
- Adds a Ruby DSL loader (`Wheneverd::DSL::Loader.load_file`) supporting `every(...)` blocks with `command(...)` jobs.
- Schedule DSL: `every` accepts multiple calendar period symbols in one block (e.g. `every :tuesday, :wednesday`).
- Cron strings: supports standard 5-field crontab syntax (including month/day-of-week and steps); expressions that require
  cron day-of-month vs day-of-week OR semantics may expand into multiple `OnCalendar=` lines.
- Adds systemd unit rendering (`Wheneverd::Systemd::Renderer.render`) for interval and calendar triggers.
- Systemd: unit basenames use a stable ID derived from the job’s trigger + command (reordering schedule blocks won’t rename units).
- Interval timers now include both `OnActiveSec=` and `OnUnitActiveSec=` so newly enabled timers have a next run scheduled.
- Adds helpers to write and delete generated unit files (`Wheneverd::Systemd::UnitWriter`/`UnitDeleter`).
- Adds CLI subcommands: `init`, `show`, `write`, `delete`, `activate`, `deactivate`, `reload`, and `current`.
- `wheneverd init` prints whether it wrote or overwrote the schedule template.
- Schedule DSL supports `every :reboot` as a boot trigger (rendered as `OnBootSec=1`).
- Developer: `rake ci` runs with Bundler setup (so it works without `bundle exec` after `bundle install`).
- Developer: adds YARD tasks (`rake yard` / `rake doc`) and inline API documentation.
- CLI: `delete` / `current` only operate on units matching the identifier and generated marker.
- CLI: `write` / `reload` prune previously generated units for the identifier by default (use `--no-prune` to disable pruning).
