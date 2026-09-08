# Milestone 5: Flare Compile Integration

## Learning objective

Prove that the chosen generated form works with pinned released Flare across realistic multi-module handlers before packaging the tool.

## Capability

- end-to-end generated route file
- cross-module handler imports
- repeated handler registration
- minimal fixture application that instantiates `ComptimeRouter`

## Expected files

- `examples/fixture_app/...`
- integration tests
- pinned Flare test fixture wiring

## Tests

- generated file compiles against pinned Flare
- handlers from multiple modules compile in one route table
- repeated handler registration compiles
- optional in-process route verification via Flare `TestClient`

## Exact commands

```bash
pixi run flare-routegen -- generate --source examples/fixture_app/src --package my_app --output examples/fixture_app/src/my_app/_generated_routes.mojo
pixi run mojo run -I examples/fixture_app/src examples/fixture_app/src/my_app/app.mojo
pixi run test
```

## Definition of done

- compile-time architecture is proven in this repository
- generated code works with pinned released Flare
- no blocker remains in the first five milestones

## Suggested commit boundaries

1. fixture app
2. compile integration test
3. in-process verification additions

## Code-reading checkpoint for Joseph

Read the fixture app and its generated routes file together to confirm that the generated result is acceptable to commit and review.

## Coding-agent prompt

Add a minimal multi-module Flare fixture app and integration tests proving that `flare-routegen` generates compile-time routes that compile and dispatch correctly against pinned Flare.
