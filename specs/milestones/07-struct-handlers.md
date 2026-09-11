# Milestone 7: Typed Extractors via Existing Flare APIs

## Learning objective

Register Flare typed-extractor handler structs through generated glue without reimplementing extractors, dispatch, or middleware.

## Capability

- associate `# @flare.route` with the next top-level `def` or `struct`
- comptime wrappers call `Extracted[H]().serve(req)` so `ComptimeRoute` stays a function pointer
- runtime fallback emits `router.get[Extracted[H]](path, Extracted[H]())`
- mixed function and struct tables remain deterministic

## Expected files

- `src/flare_routegen/models.mojo`
- `src/flare_routegen/scan.mojo`
- `src/flare_routegen/render_comptime.mojo`
- `src/flare_routegen/render_runtime.mojo`
- `src/flare_routegen/module_map.mojo`
- `test/fixtures/probes/association/struct_handler.mojo`
- `test/fixtures/probes/association/fieldwise_init_struct.mojo`
- `test/fixtures/probes/association/multiple_directives_struct.mojo`
- `test/fixtures/probes/association/nested_struct.mojo`
- `examples/fixture_app/src/my_app/views/users.mojo`

## Tests

- struct association, `@fieldwise_init` between directive and struct, multiple directives, nested struct
- comptime output imports `Extracted` and calls `Extracted[alias]().serve(req)`
- runtime output emits `router.get[Extracted[alias]]` and does not wrap structs as functions
- function-only golden `app_basic` is unchanged
- fixture `GetUser` with `PathInt["id"]` dispatches `/users/42` and returns 400 for `/users/abc`

## Exact commands

```bash
pixi run fmt
pixi run generate-fixture
pixi run test
pixi run flare-routegen -- check --source examples/fixture_app/src --package my_app --output examples/fixture_app/src/my_app/_generated_routes.mojo
```

## Definition of done

- extractor structs are discovered and registered through public Flare APIs
- `ComptimeRouter[ROUTES]` still compiles against Flare
- middleware remains application-owned wrapping of the generated handler

## Suggested commit boundaries

1. scanner `handler_kind` and association probes
2. comptime and runtime renderers
3. fixture app and integration 400 path

## Code-reading checkpoint for Joseph

Compare `examples/fixture_app/src/my_app/views/users.mojo` with the generated wrapper in `_generated_routes.mojo` and confirm it matches Flare's `Extracted[GetUser]` registration, not a second extractor implementation.

## Coding-agent prompt

Discover top-level Flare extractor handler structs and emit existing `Extracted[H]` registration. Keep `ComptimeRouter` as the primary table via function-pointer wrappers. Do not parse extractor fields or generate middleware.
