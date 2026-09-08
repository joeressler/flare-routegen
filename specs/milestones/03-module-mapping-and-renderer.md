# Milestone 3: Module Mapping and Deterministic Renderer

## Learning objective

Lock the generated-code shape and deterministic ordering rules before any file-writing behavior is introduced.

## Capability

- source file to Mojo module mapping
- deterministic handler import aliasing
- generated raising wrapper functions
- compile-time `ROUTES` rendering in memory

## Expected files

- `src/flare_routegen/module_map.mojo`
- `src/flare_routegen/render_comptime.mojo`
- `src/flare_routegen/render_runtime.mojo`
- `test/test_module_map.mojo`
- `test/test_render_comptime.mojo`
- `test/fixtures/golden/...`

## Tests

- exact-byte golden output tests
- duplicate route rejection
- stable import alias generation
- deterministic output under reversed discovery order

## Exact commands

```bash
pixi run test
```

## Definition of done

- renderer emits the selected compile-time output form
- one raising wrapper is emitted per unique handler
- byte-determinism is proven by golden tests

## Suggested commit boundaries

1. module-path mapping
2. import/wrapper renderer
3. golden tests and determinism checks

## Code-reading checkpoint for Joseph

Review the golden output next to the source fixtures to confirm that naming, ordering, and wrapper generation are readable and unsurprising.

## Coding-agent prompt

Implement deterministic compile-time route rendering for discovered routes, including module-path mapping, alias imports, and one raising wrapper per unique handler. Add exact-byte golden tests.
