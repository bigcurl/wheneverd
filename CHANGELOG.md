# Changelog

This project keeps all changes in `## Unreleased` until the CLI and generated systemd output settle.
Once releases begin, entries will be moved into `## x.y.z` sections that match the gem version.

## Unreleased

- Provides a Clamp-based `wheneverd` CLI with `--help`, `--version`, and `--verbose` (help/usage and errors follow Clamp defaults).
- Adds core domain objects and helpers for building schedules (interval parsing, durations, triggers, entries, jobs).
- Adds a Ruby DSL loader (`Wheneverd::DSL::Loader.load_file`) supporting `every(...)` blocks with `command(...)` jobs.
- Adds systemd unit rendering (`Wheneverd::Systemd::Renderer.render`) for interval, calendar, and reboot triggers.
- Adds helpers to write and delete generated unit files (`Wheneverd::Systemd::UnitWriter`/`UnitDeleter`).
- Adds CLI subcommands: `init`, `show`, `write`, and `delete`.
- `wheneverd init` prints whether it wrote or overwrote the schedule template.
