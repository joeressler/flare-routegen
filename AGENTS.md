# Agent notes for flare-routegen

Generate Flare `ComptimeRoute` glue from `# @flare.route METHOD PATH` comments.
This is not a web framework. Do not implement routing, HTTP, middleware,
extractors, OpenAPI, or application contexts.

Read [`specs/flare-routegen-v0.1-spec.md`](specs/flare-routegen-v0.1-spec.md)
before changing discovery, rendering, diagnostics, or CLI semantics. If code
and spec disagree, fix both in the same change. Human workflow is in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Hard constraints

- Do not switch Flare to the conda/pixi-build `v0.10.0` package. Keep
  `flare = { git = "https://github.com/ehsanmok/flare.git", branch = "main" }`
  in `pixi.toml`. That published artifact cannot be installed with Pixi
  `0.70.2`.
- The generator CLI must not import Flare. Only generated apps and
  `test/test_flare_integration.mojo` import `flare.http`.
- `conda.recipe/recipe.yaml` must not add a Flare conda dependency. It builds
  a CLI (`mojo build -I src src/main.mojo`), not a `.mojoc` library. In-repo
  source is `path: ..`.
- Never rewrite user source. `generate` overwrites only files that already
  carry both generated markers; `check` compares formatted bytes.
- Do not implement `FRG016` unless a task explicitly asks for it. Keep
  `FLARE_RANGE` as the API range and `FLARE_PIN_CI = "main"` in
  `src/flare_routegen/version.mojo`.
- Do not add real decorators, a general Mojo parser, Python-first CLI, or a
  config file for v0.1.
- Reuse existing modules. Do not add a second scanner, renderer, or CLI.

## Layout

| Path | Role |
| --- | --- |
| `src/main.mojo` | CLI entry |
| `src/flare_routegen/` | scan, discover, render, output, CLI |
| `examples/fixture_app/src/main.mojo` | executable beside package |
| `examples/fixture_app/src/my_app/` | library + committed `_generated_routes.mojo` |
| `test/test_*.mojo` | suite (`scripts/run-tests.sh`) |
| `test/fixtures/` | association probes, golden apps |
| `conda.recipe/recipe.yaml` | CLI package |
| `specs/milestones/` | historical milestone contracts |

Mojo forbids `main()` inside a package. Keep `main.mojo` outside `my_app/`.

## Commands

```bash
pixi install
pixi run fmt
pixi run fmt-check
pixi run test
pixi run generate-fixture
pixi run check-fixture
pixi run run-fixture
```

- `pixi run test` runs each `test/test_*.mojo` with `mojo run`. Do not use
  `mojo test`.
- Integration tests need `-I examples/fixture_app/src` (already in
  `scripts/run-tests.sh`).
- After renderer/scanner changes: `pixi run generate-fixture` and commit
  `_generated_routes.mojo`. `check-fixture` must stay green.
- `fmt-check` is `mojo format` then `git diff --exit-code`. CI checkouts are
  clean; a dirty local tree fails even if format is a no-op.
- Full `pixi run test` can take tens of minutes. Prefer the relevant
  `test/test_*.mojo` while iterating, then the full suite before done.
- Optional package check: `rattler-build build --recipe conda.recipe/recipe.yaml`
  with Modular + conda-forge + modular-community channels. Output is
  gitignored under `/output/`.

## Implementation notes

- Association: next top-level `def` or `struct`. Nested handlers do not bind
  (`FRG007`). `handler_kind` is `"function"` or `"struct"`.
- Comptime structs wrap as `Extracted[alias]().serve(req)` because
  `ComptimeRoute` stores a function pointer. Import `Extracted` only when a
  struct is present so function-only goldens stay stable.
- Runtime structs use `router.get[Extracted[alias]](path, Extracted[alias]())`.
  Do not emit a function wrapper for structs.
- Primary output is comptime (`renderer=comptime`). Do not make runtime the
  default.
- Diagnostics: add the code in `diagnostics.mojo`, the spec catalog, and a
  test. Do not reuse or renumber `FRG001`–`FRG018`.
- Mojo 1.0: `def` not `fn`, `comptime` not `alias`,
  `from std.testing import ...`.
- Comments describe purpose, not effect. No placeholders or unfinished TODOs
  in landed code.

Compiler warnings under `.pixi/envs/default/lib/mojo/flare/` are Flare's.
`[flare:bad-request] expected integer, got 'abc'` is Extracted logging, not a
generator failure.

## Pins

| Component | CI pin | Range |
| --- | --- | --- |
| Mojo | `1.0.0` | `>=1.0.0,<1.1.0` |
| Flare | git `main` | API `>=0.10.0,<0.11.0` |
| Pixi | `0.70.2` | exact in CI |

CI: `.github/workflows/ci.yml` — `ubuntu-latest`, `gcc`, Pixi `v0.70.2`,
`fmt-check`, `test`, `check-fixture`, plus a hard-fail recipe build.
