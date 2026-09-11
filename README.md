# flare-routegen

Generate deterministic Flare route registrations from structured Mojo comment
directives. User source stays valid Mojo; the tool discovers top-level
`# @flare.route <METHOD> <PATH>` comments and emits compile-time `ComptimeRoute`
glue through public Flare APIs.

This is **not** a Flask-like framework. It does not implement routing, HTTP
behavior, middleware, or application contexts.

## Pinned compatibility

| Component | CI / validation pin | Supported range |
| --- | --- | --- |
| Mojo | `1.0.0` | `>=1.0.0,<1.1.0` |
| Flare | `v0.10.0` | `>=0.10.0,<0.11.0` |
| Pixi | `0.70.2` | exact in CI (milestone 6) |

Flare is documented here but not installed until the Flare integration milestone.

## Milestone 4 status

`list` scans typed Mojo source for top-level `# @flare.route` directives and
prints a stable route inventory. `generate` renders compile-time route glue,
formats it with `mojo format`, and atomically replaces the output file.
`check` compares exact formatted bytes and fails when output is missing or stale.
Overwrite is allowed only when the destination already contains the generated
marker lines. User source files are never rewritten.

## Setup

Requires [Pixi](https://pixi.sh/) and a C linker (`gcc` on Linux).

```bash
pixi install
pixi run flare-routegen -- --version
pixi run flare-routegen -- list --source test/fixtures/app_basic/src --package my_app
pixi run flare-routegen -- generate --source test/fixtures/app_basic/src --package my_app --output /tmp/flare-routegen-routes.mojo
pixi run flare-routegen -- check --source test/fixtures/app_basic/src --package my_app --output /tmp/flare-routegen-routes.mojo
pixi run test
```

Format sources:

```bash
pixi run fmt
```

## Specification

See [`specs/flare-routegen-v0.1-spec.md`](specs/flare-routegen-v0.1-spec.md) for
the full v0.1 architecture, directive grammar, diagnostics, and roadmap.
