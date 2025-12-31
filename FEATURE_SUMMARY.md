# Feature Summary

This file tracks the most important *user-visible* behavior changes in `wheneverd`.
It complements [`CHANGELOG.md`](CHANGELOG.md) by staying high-level and focusing on what users will notice.

## How to update

- Update `## Unreleased` in commits that change user-facing behavior (CLI UX, defaults, generated output, breaking changes).
- Skip internal refactors, tests, and docs-only tweaks unless they affect users.
- Keep entries short, written from the user’s point of view.
- On release, move items from `## Unreleased` into a new `## x.y.z` section that matches the gem version.

## Unreleased

- The `wheneverd` CLI is implemented using the Clamp gem (help/usage and errors follow Clamp defaults).
- The gem includes a small “whenever-like” domain model (interval parsing, durations, triggers, schedules).
- The gem can load a Ruby schedule DSL file via `Wheneverd::DSL::Loader.load_file`.
- Schedule DSL supports `every(period, at: ..., roles: ...) { command("...") }` entries (multiple `command` calls per entry).
- Supported `every` periods include interval strings/durations, calendar shortcuts (`:hour`, `:day`, `:month`, `:year`),
  day selectors (`:monday..:sunday`, `:weekday`, `:weekend`), and a limited subset of 5-field cron strings.
- `at:` supports a string or an array of strings (for calendar schedules), like `"4:30 am"` or `"00:15"`.
- `roles:` is accepted and stored on entries, but is not used for filtering yet.
- The gem can render systemd `.service` and `.timer` units via `Wheneverd::Systemd::Renderer.render`.
- The gem can write/delete generated unit files via `Wheneverd::Systemd::UnitWriter` and `Wheneverd::Systemd::UnitDeleter`.
- The `wheneverd` CLI supports `init`, `show`, `write`, and `delete` for working with schedule files and user unit directories.
- `wheneverd init` prints whether it wrote or overwrote the schedule template.
- Using `every :reboot` raises an error (the `:reboot` period shortcut is not supported).
