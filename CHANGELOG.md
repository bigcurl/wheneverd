# Changelog

## Unreleased

- Provides a Clamp-based `wheneverd` CLI with `--help`, `--version`, and `--verbose` (help/usage and errors follow Clamp defaults).
- Adds core domain objects and helpers for building schedules (interval parsing, durations, triggers, entries, jobs).
- Adds a Ruby DSL loader (`Wheneverd::DSL::Loader.load_file`) supporting `every(...)` blocks with `command(...)` jobs.
- Does not generate systemd units/timers yet.
