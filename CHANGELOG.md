# Changelog

This project keeps all changes in `## Unreleased` until the CLI and generated systemd output settle.
Once releases begin, entries will be moved into `## x.y.z` sections that match the gem version.

## Unreleased

- Provides a Clamp-based `wheneverd` CLI with `--help`, `--version`, and `--verbose` (usage errors in `ERROR: ...` format).
- Adds core domain objects and helpers for building schedules (interval parsing, durations, triggers, entries, jobs).
- Adds a Ruby DSL loader (`Wheneverd::DSL::Loader.load_file`) supporting `every(...)` blocks with `command(...)` jobs.
- Schedule DSL: `every` accepts multiple calendar period symbols in one block (e.g. `every :tuesday, :wednesday`).
- Adds systemd unit rendering (`Wheneverd::Systemd::Renderer.render`) for interval and calendar triggers.
- Adds helpers to write and delete generated unit files (`Wheneverd::Systemd::UnitWriter`/`UnitDeleter`).
- Adds CLI subcommands: `init`, `show`, `write`, `delete`, `activate`, `deactivate`, `reload`, and `current`.
- `wheneverd init` prints whether it wrote or overwrote the schedule template.
- Using `every :reboot` now raises an error (the `:reboot` period shortcut is not supported).
- Developer: `rake ci` runs with Bundler setup (so it works without `bundle exec` after `bundle install`).
- Developer: adds YARD tasks (`rake yard` / `rake doc`) and inline API documentation.
- CLI: `delete` / `current` only operate on units matching the identifier and generated marker.
