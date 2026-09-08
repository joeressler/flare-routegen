# Milestone 6: Packaging, CI, and Documentation

## Learning objective

Turn the validated prototype into a repeatable developer tool that is easy to install, test, and keep fresh in CI.

## Capability

- repository CI
- Pixi tasks for test/format/check flows
- packaging recipe
- user-facing setup and usage documentation

## Expected files

- `.github/workflows/ci.yml`
- `conda.recipe/recipe.yaml`
- finalized `README.md`
- `CHANGELOG.md`

## Tests

- CI runs formatting and tests
- CI runs generated-file freshness checks
- packaging recipe validates the executable/install surface

## Exact commands

```bash
pixi run fmt
pixi run test
pixi run flare-routegen -- check --source examples/fixture_app/src --package my_app --output examples/fixture_app/src/my_app/_generated_routes.mojo
```

## Definition of done

- setup and usage are documented from a clean clone
- CI detects drift in generated output
- packaging metadata is ready for community distribution

## Suggested commit boundaries

1. CI workflow
2. package recipe
3. end-user documentation

## Code-reading checkpoint for Joseph

Follow the README from a clean checkout and confirm that the documented setup, generate, and check commands match the intended project ergonomics.

## Coding-agent prompt

Finalize `flare-routegen` for external use with Pixi tasks, CI, packaging metadata, and user documentation. Keep the implementation Mojo-native and preserve the previously selected generation architecture.
