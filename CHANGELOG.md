# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-11

### Added

- Mojo-native `generate`, `check`, `list`, `help`, and `version` commands.
- Top-level `# @flare.route <METHOD> <PATH>` discovery for `def` and `struct`
  handlers, with stable diagnostics (`FRG001`–`FRG015`, `FRG017`, `FRG018`).
- Compile-time `ComptimeRoute` output as the primary renderer; runtime
  `Router` registration as an internal fallback.
- Typed-extractor structs registered through Flare's existing `Extracted[H]`
  API (`PathInt` and related extractors stay in Flare).
- Fixture app at `examples/fixture_app/` with `main.mojo` outside the `my_app`
  package.
- Pixi tasks: `fmt`, `fmt-check`, `test`, `generate-fixture`, `check-fixture`,
  `run-fixture`.
- GitHub Actions CI (format, tests, fixture freshness) and a
  `conda.recipe/recipe.yaml` that builds the CLI without a Flare conda
  dependency.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md) for
  humans and coding agents.

### Notes

- Flare is installed from git `main`. The pixi-build package for Flare
  `v0.10.0` cannot be installed with Pixi `0.70.2`.
