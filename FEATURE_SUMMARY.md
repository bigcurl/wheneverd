# Feature Summary

This file tracks the most important *user-visible* behavior changes in `wheneverd`.
It complements [`CHANGELOG.md`](CHANGELOG.md) by staying high-level and focusing on what users will notice.

## How to update

- Update `## Unreleased` in commits that change user-facing behavior (CLI UX, defaults, generated output, breaking changes).
- Skip internal refactors, tests, and docs-only tweaks unless they affect users.
- Keep entries short, written from the user’s point of view.
- On release, move items from `## Unreleased` into a new `## x.y.z` section that matches the gem version.

## Unreleased

- (none yet)

## 0.1.0

- Adds a scaffold `wheneverd` CLI with `--help`, `--version`, and `--verbose`.
- With no arguments, prints help to stderr and exits non-zero (placeholder behavior).
- Does not generate systemd units/timers yet.
