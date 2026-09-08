# Milestone 1: Skeleton, Pins, and Probe Harness

## Learning objective

Lock the released-version assumptions, establish repository structure, and make the planned architecture explicit before implementing scanning or generation.

## Capability

- Mojo-native CLI skeleton
- help/version output
- pinned compatibility documentation
- disposable probe fixtures and harness scaffolding

## Expected files

- `pixi.toml`
- `scripts/run-tests.sh`
- `src/flare_routegen/__init__.mojo`
- `src/flare_routegen/cli.mojo`
- `src/flare_routegen/version.mojo`
- `test/test_cli.mojo`
- `test/fixtures/probes/...`
- `README.md`

## Tests

- CLI help/version smoke tests
- repository bootstrap smoke test

## Exact commands

```bash
pixi install
pixi run flare-routegen -- --version
pixi run test
```

## Definition of done

- repo installs and runs through Pixi
- CLI skeleton exists and prints help/version
- pinned Mojo/Flare compatibility is documented
- no scanner or generator behavior is implemented yet

## Suggested commit boundaries

1. Pixi and test-runner scaffold
2. CLI help/version surface
3. probe fixtures and planning docs

## Code-reading checkpoint for Joseph

Review the project layout, `pixi.toml`, and the CLI entrypoint to confirm the repository shape and toolchain expectations before behavior is added.

## Coding-agent prompt

Create a Mojo-native CLI skeleton for `flare-routegen` with Pixi support, a test runner script, help/version output, and pinned Mojo/Flare compatibility documentation. Do not implement scanning or generation yet.
