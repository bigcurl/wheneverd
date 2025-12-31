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
- With no arguments, prints help to stderr and exits non-zero (placeholder behavior).
- The gem includes a small “whenever-like” domain model (interval parsing, durations, triggers, schedules).
- Does not generate systemd units/timers yet.
