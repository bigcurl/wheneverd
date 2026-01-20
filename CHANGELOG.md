# Changelog

This project keeps all changes in `## Unreleased` until they are released.
On release, entries are moved into `## x.y.z` sections that match the gem version.

## Unreleased

## 0.4.0

- Docs: adds a copy/paste "deploy a simple schedule" example and refines README status section.
- Refactor: extracts `UnitPathUtils` module for shared identifier/path utilities across `UnitWriter`, `UnitDeleter`, `UnitLister`, and `Renderer`.
- Refactor: adds polymorphic `Trigger::Base` interface with `#systemd_timer_lines` and `#signature` methods for all trigger types.
- Refactor: splits `CronParser` into focused `FieldParser` and `DowParser` submodules for maintainability.
- Refactor: implements strategy pattern for `PeriodParser` with dedicated strategies for Duration, String, Symbol, and Array inputs.
- Refactor: extracts `UnitContentBuilder` from `Renderer` for cleaner separation of unit content generation.
- Refactor: adds `Validation` module with composable validators (`type`, `positive_integer`, `non_empty_string`, `non_empty_array`, `in_range`).

## 0.3.0

- Schedule DSL: `command` accepts argv arrays, adds a `shell` helper for `/bin/bash -lc`, and `wheneverd init` includes examples.
- Adds `wheneverd status` (show `systemctl --user list-timers` + `systemctl --user status` for installed timers) and `wheneverd diff` (diff rendered units vs files on disk).
- Adds `wheneverd validate` to validate rendered `OnCalendar=` values via `systemd-analyze calendar` (and with `--verify`, runs `systemd-analyze --user verify` on temporary unit files).

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
