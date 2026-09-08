# Milestone 2: Scanner, Diagnostics, and `list`

## Learning objective

Prove that comment-based implicit association to the next top-level handler is robust enough for v0.1 without introducing a general Mojo parser.

## Capability

- route directive scanning
- top-level handler association
- validation and diagnostics
- `list` command output

## Expected files

- `src/flare_routegen/grammar.mojo`
- `src/flare_routegen/diagnostics.mojo`
- `src/flare_routegen/models.mojo`
- `src/flare_routegen/scan.mojo`
- `src/flare_routegen/discover.mojo`
- `test/test_scan.mojo`
- `test/test_diagnostics.mojo`
- `test/fixtures/app_basic/...`
- `test/fixtures/app_invalid/...`

## Tests

- valid directive cases
- malformed directives
- unsupported methods
- orphan directives
- nested handlers
- decorators between directive and handler
- multiline signatures
- fake directive text in strings/comments

## Exact commands

```bash
pixi run test
pixi run flare-routegen -- list --source test/fixtures/app_basic/src --package my_app
```

## Definition of done

- top-level discovery works in stable order
- requested scanner diagnostics exist with stable codes
- `list` prints one stable row per discovered route

## Suggested commit boundaries

1. models and diagnostics
2. scanner state machine
3. `list` command and fixture tests

## Code-reading checkpoint for Joseph

Read the scanner state machine and fixture corpus to verify that the supported grammar and unsupported cases match the intended authoring experience.

## Coding-agent prompt

Implement the comment-directive scanner for top-level Mojo handlers, with stable diagnostics and a `list` command. Use implicit next-top-level-def association and do not implement generation yet.
