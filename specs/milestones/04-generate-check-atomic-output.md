# Milestone 4: `generate`, `check`, and Atomic Output

## Learning objective

Make route generation safe for local development and CI by locking overwrite, formatting, stale-checking, and atomic replace semantics.

## Capability

- `generate` command
- `check` command
- safe overwrite policy
- sibling temp-file writes
- formatter integration
- stale-output detection

## Expected files

- `src/flare_routegen/output.mojo`
- `src/flare_routegen/format.mojo`
- expanded `src/flare_routegen/cli.mojo`
- `test/test_output.mojo`
- expanded `test/test_cli.mojo`

## Tests

- generated marker enforcement
- unsafe overwrite failure
- stale output failure
- missing output failure
- formatter failure path
- output-inside-source-tree validation
- source-mutation detection

## Exact commands

```bash
pixi run flare-routegen -- generate --source test/fixtures/app_basic/src --package my_app --output test/fixtures/app_basic/src/my_app/_generated_routes.mojo
pixi run flare-routegen -- check --source test/fixtures/app_basic/src --package my_app --output test/fixtures/app_basic/src/my_app/_generated_routes.mojo
pixi run test
```

## Definition of done

- `generate` writes only after full validation succeeds
- output replacement is atomic
- `check` compares exact formatted bytes
- overwrite rules are unambiguous and enforced

## Suggested commit boundaries

1. formatter/process wrapper
2. atomic output path
3. `check` command and safety tests

## Code-reading checkpoint for Joseph

Verify the overwrite policy, marker format, and stale-output semantics against how you want the tool to behave in everyday developer workflows.

## Coding-agent prompt

Implement the `generate` and `check` commands with safe overwrite rules, sibling-temp atomic writes, formatting integration, exact-byte stale detection, and tests for failure paths.
