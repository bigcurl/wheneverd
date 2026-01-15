# Agent Notes (wheneverd)

## Project

`wheneverd` is a Ruby gem that aims to generate `systemd` timer/service units from a Ruby DSL (analogous to the `whenever` gem for cron). The current state is an early scaffold with a placeholder CLI; systemd generation is not implemented yet.

Primary docs:
- `README.md` for usage and dev setup.
- `FEATURE_SUMMARY.md` for user-visible behavior changes.
- `CHANGELOG.md` for versioned release notes.

Documentation hygiene:
- After completing a prompt that changes user-visible behavior or developer workflow, update `README.md`, `FEATURE_SUMMARY.md`, and `CHANGELOG.md` as needed.
- Before committing any change, run `bundle exec rake ci`; it must complete with no errors (fix failures first).
- When implementing or changing behavior, add/adjust tests to tighten the implementation and prevent regressions.
- When committing, commit only the changes from the current session: stage explicit files (or use `git add -p`) and avoid committing unrelated modified files.

## Repo Layout

- `lib/wheneverd.rb`: gem entrypoint.
- `lib/wheneverd/cli.rb`: Clamp-based CLI (currently prints help / version only).
- `lib/wheneverd/version.rb`: gem version.
- `exe/wheneverd`: executable entrypoint.
- `test/`: Minitest suite (with SimpleCov configured in `test/test_helper.rb`).
- `Rakefile`: CI-like tasks for lint + tests.

## Common Commands

- Install deps: `bundle install`
- Run tests: `bundle exec rake test`
- Run RuboCop (autocorrect): `bundle exec rake ci:rubocop`
- Run lint + tests (default): `bundle exec rake ci`

Notes:
- `bundle exec rake ci` runs `rubocop -A .` (it may modify files) and then runs tests.
- Tests write coverage output to `coverage/`. Coverage threshold defaults to 100% and can be set via `MINIMUM_COVERAGE` (e.g. `MINIMUM_COVERAGE=95 bundle exec rake test`).

## Conventions

- Ruby target is 2.7 (`.rubocop.yml` / gemspec).
- Prefer double-quoted strings and keep lines <= 100 chars (RuboCop).
- Add/update `FEATURE_SUMMARY.md` only for user-visible changes (CLI UX, defaults, generated output, breaking changes).
