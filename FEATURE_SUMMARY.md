# Feature Summary

This file tracks the most important *user-visible* behavior changes in `wheneverd`.
It complements [`CHANGELOG.md`](CHANGELOG.md) by staying high-level and focusing on what users will notice.

## How to update

- Update `## Unreleased` in commits that change user-facing behavior (CLI UX, defaults, generated output, breaking changes).
- Skip internal refactors, tests, and docs-only tweaks unless they affect users.
- Keep entries short, written from the user’s point of view.
- On release, move items from `## Unreleased` into a new `## x.y.z` section that matches the gem version.

## Unreleased

- Adds `wheneverd linger enable|disable|status` for managing systemd user lingering via `loginctl`.
- Removes an unused filtering metadata keyword argument from the schedule DSL.

## 0.2.0

- The `wheneverd` CLI is implemented using Clamp (`--help`, usage errors in `ERROR: ...` format, `--verbose` for details).
- The gem includes a small “whenever-like” domain model (interval parsing, durations, triggers, schedules).
- The gem can load a Ruby schedule DSL file via `Wheneverd::DSL::Loader.load_file`.
- Schedule DSL supports `every(period, at: ...) { command("...") }` entries (multiple `command` calls per entry).
- Schedule DSL supports multiple calendar period symbols per `every` block (e.g. `every :tuesday, :wednesday`).
- Supported `every` periods include interval strings/durations, calendar shortcuts (`:hour`, `:day`, `:month`, `:year`),
  day selectors (`:monday..:sunday`, `:weekday`, `:weekend`), and standard 5-field cron strings.
- `at:` supports a string or an array of strings (for calendar schedules), like `"4:30 am"` or `"00:15"`.
- The gem can render systemd `.service` and `.timer` units via `Wheneverd::Systemd::Renderer.render`.
- Generated unit basenames include a stable ID derived from the job’s trigger + command (reordering schedule blocks won’t rename units).
- Interval timers include both `OnActiveSec=` and `OnUnitActiveSec=` to ensure a newly started timer has a next run scheduled.
- The gem can write/delete generated unit files via `Wheneverd::Systemd::UnitWriter` and `Wheneverd::Systemd::UnitDeleter`.
- The `wheneverd` CLI supports `init`, `show`, `write`, `delete`, `activate`, `deactivate`, and `reload` for working with
  schedule files, unit directories, and managing user timers via `systemctl --user`.
- `wheneverd write` / `wheneverd reload` prune previously generated units for the identifier by default (use `--no-prune` to disable pruning).
- The `wheneverd current` command prints the currently installed unit file contents from disk for an identifier.
- The `wheneverd delete` / `wheneverd current` commands only operate on units matching the identifier and generated marker.
- `wheneverd init` prints whether it wrote or overwrote the schedule template.
- Schedule DSL supports `every :reboot` as a boot trigger (rendered as `OnBootSec=1`).
