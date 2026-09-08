# flare-routegen v0.1 Specification

## Status

Implementation-ready planning document derived from the repository plan. This document defines the recommended v0.1 architecture, behavior, diagnostics, and roadmap for `flare-routegen` without implementing production code.

## Problem

`flare-routegen` gives Flare users a temporary Flask-like route-decorator authoring experience while keeping input as valid Mojo source. Because Mojo does not currently provide stable user-defined decorators or macros for attaching arbitrary metadata to functions, the tool will discover structured comments and generate ordinary Flare route registrations through public APIs.

## Users

- Flare application authors using Mojo
- Repository maintainers who want deterministic generated route glue in source control
- CI systems that need to detect stale generated output

## Goals

- Keep annotated user input valid Mojo
- Discover top-level handlers across a declared source/package root
- Validate a small documented annotation grammar
- Generate readable deterministic Mojo through public Flare APIs
- Support multiple routes on one handler
- Detect malformed directives, orphan directives, ambiguous imports, and duplicate method/path registrations
- Never rewrite user source files
- Refuse to overwrite an output file that lacks the generated marker
- Provide `generate`, `check`, `list`, `help`, and `version` commands
- Integrate with Pixi and ordinary Mojo builds
- Prefer a Mojo-native executable
- Pin and document compatible Mojo and Flare versions

## Non-goals

`flare-routegen` does not implement routing, matching, dispatch, HTTP behavior, middleware, OpenAPI generation, templates, sessions, auth, application contexts, compiler extensions, or a Flask-like framework.

## Pinned compatibility recommendation

| Component | Pin for CI and validation | Supported range |
| --- | --- | --- |
| Mojo | `1.0.0` | `>=1.0.0,<1.1.0` |
| Flare | `v0.10.0` | `>=0.10.0,<0.11.0` |
| Pixi | `v0.70.2` | exact in CI |

## Research findings

### Released version evidence

- Mojo release tag `mojo/v1.0.0`, commit `b4497b7ce9ba96331c72c637ad41b44bab374f33`
- Flare release tag `v0.10.0`, commit `7041eccbc39d59eb4a56fb42d45013b213466cec`
- Flare CI succeeded on the `v0.10.0` tag commit via workflow run `31552065994`

### Flare API evidence

Released Flare source at `v0.10.0` publicly exports:

- `ComptimeRoute`
- `ComptimeRouter`
- runtime `Router`
- `Method`
- `Request`
- `Response`

Relevant evidence locations:

- `flare/http/routes.mojo`
- `flare/http/router.mojo`
- `flare/http/__init__.mojo`
- `examples/advanced/comptime_router.mojo`
- `tests/http/test_routes_comptime.mojo`
- `examples/intermediate/infallible_handler.mojo`
- `tests/http/test_router_copy.mojo`
- `flare/testing/client.mojo`

### Mojo language/tooling evidence

Released Mojo documentation supports:

- compile-time reflection via `reflect[T]`
- compile-time values and `comptime for`
- packages/modules
- filesystem/path/process tooling in the standard library
- packaging via Pixi and `rattler-build`

Released Mojo documentation does not provide stable user-defined decorators or macro/plugin APIs suitable for route annotations. Reflection is documented as newly introduced and incomplete, so route discovery should not depend on deep parser or reflection features.

### Ecosystem search results

- No public Mojo or Flare route generator was found
- No public Flare annotation tool was found
- No `modular-community` recipe for a Flare route generator was found
- Adjacent ecosystem references worth borrowing patterns from:
  - `forfudan/argmojo` for CLI packaging patterns
  - `joeressler/heat-url` for Pixi/CI/recipe conventions

## Mandatory probe outcomes

### Probe 1: compile-time Flare route table

Result: supported through released Flare public APIs.

Evidence:

- `examples/advanced/comptime_router.mojo`
- `tests/http/test_routes_comptime.mojo`
- Flare CI run on tag commit `7041ecc...`

Conclusion: select compile-time generation as the primary v0.1 renderer.

### Probe 2: generated-style module imported by an app

Result: supported.

Evidence:

- released Flare example instantiates `ComptimeRouter[ROUTES]()`
- public exports verified from `flare/http/__init__.mojo`

Conclusion: generated module can safely export `ROUTES`.

### Probe 3: runtime fallback registration function

Result: valid through public `Router` methods.

Evidence:

- `flare/http/router.mojo`
- `examples/intermediate/infallible_handler.mojo`
- `tests/http/test_router_copy.mojo`

Conclusion: keep a runtime renderer as an internal fallback path, not the primary v0.1 output.

### Probe 4: annotation scanner fixture

Local disposable probe showed that implicit association to the next top-level `def` is feasible without a general Mojo parser. The probe handled blank lines, decorators, multiline signature starts, multiple directives, fake directive text inside strings, and detected orphaned/nested cases.

Conclusion: choose implicit association.

### Probe 5: deterministic generation under different enumeration order

Local disposable probe produced identical bytes after sorting discovered routes by stable keys.

Conclusion: determinism is straightforward if ordering is explicit.

## Recommended architecture

Build `flare-routegen` as a Mojo-native CLI that:

1. Scans structured top-level comment directives
2. Associates each directive with the next top-level handler
3. Validates and normalizes discovered routes
4. Generates deterministic compile-time Flare route code
5. Writes output atomically after formatting

### Selected output form

Primary output is a compile-time route table for `ComptimeRouter`.

Generated shape:

```mojo
# Generated by flare-routegen. Do not edit.
# flare-routegen: format=1 renderer=comptime

from flare.http import ComptimeRoute, Method, Request, Response
from my_app.views import home as _frg_my_app_views_home
from my_app.views import show_user as _frg_my_app_views_show_user

def _frg_wrap_my_app_views_home(req: Request) raises -> Response:
    return _frg_my_app_views_home(req)

def _frg_wrap_my_app_views_show_user(req: Request) raises -> Response:
    return _frg_my_app_views_show_user(req)

comptime ROUTES: List[ComptimeRoute] = [
    ComptimeRoute(Method.GET, "/", _frg_wrap_my_app_views_home),
    ComptimeRoute(Method.GET, "/users/:id", _frg_wrap_my_app_views_show_user),
    ComptimeRoute(Method.HEAD, "/users/:id", _frg_wrap_my_app_views_show_user),
]
```

### Why wrappers are required

Generated raising wrappers make the handler type uniform and explicit for `ComptimeRoute`, avoid relying on undocumented coercion edge cases, and allow one handler to be reused by multiple registrations.

## Directive grammar

### Recommendation

Support exactly one method and one path per directive in v0.1. Multiple routes on one handler are expressed by repeating directives. Do not support optional keys in v0.1.

### EBNF

```ebnf
directive_line   = ws , "#" , ws , "@flare.route" , wsp , method , wsp , path , [ wsp , inline_comment ] ;
method           = "GET" | "POST" | "PUT" | "PATCH" | "DELETE" | "HEAD" | "OPTIONS" ;
path             = "/" , { path_char } ;
path_char        = ? any non-space, non-tab, non-# character ? ;
inline_comment   = "#" , { ? any character except newline ? } ;
ws               = { " " | "\t" } ;
wsp              = ( " " | "\t" ) , { " " | "\t" } ;
```

### Semantic rules

- Directives are recognized only at top level
- A directive applies to the next top-level `def`
- Blank lines, ordinary comments, and top-level decorators may appear between directive and handler
- Any non-blank, non-comment, non-decorator top-level statement before a matching handler or end-of-file makes the directive orphaned
- Unknown tokens after the path are rejected in v0.1
- Quoted paths are rejected in v0.1
- Paths must begin with `/`
- Duplicate normalized `(method, path)` registrations are rejected project-wide

## Source discovery

- Root to scan: `join(--source, package segments...)`
- Accepted extensions: `.mojo`, `.🔥`
- Do not scan outside the declared package root
- Ignore:
  - `.git`
  - `.pixi`
  - `build`
  - `dist`
  - `target`
  - `output`
  - `__mojocache__`
  - `__pycache__`
- Do not follow directory symlinks in v0.1
- Skip symlinked files in v0.1
- Allow repeated `--exclude <glob>`
- Module path is derived from `--package` plus relative file path without extension
- Invalid module path segments are errors
- Two files mapping to one module path are errors

## CLI contract

```text
flare-routegen generate --source <dir> --package <pkg> --output <file> [--exclude <glob> ...]
flare-routegen check    --source <dir> --package <pkg> --output <file> [--exclude <glob> ...]
flare-routegen list     --source <dir> --package <pkg> [--exclude <glob> ...]
flare-routegen --help
flare-routegen --version
```

### Command behavior

- `generate`: scan, validate, render, format, atomically replace output
- `check`: scan, validate, render in memory, compare exact formatted bytes against output
- `list`: print discovered route inventory in stable order

### Exit codes

- `0`: success
- `1`: semantic failure
- `2`: CLI usage error
- `3`: tooling/runtime failure

## Determinism rules

Generated output must not include timestamps, usernames, machine paths, or randomness. For identical inputs and pinned versions, output must be byte-identical.

Stable ordering:

1. normalized module path
2. normalized source path
3. directive line
4. method
5. normalized path
6. handler symbol

## Internal model

### `DiscoveredRoute`

- `method`
- `path`
- `normalized_path`
- `handler_symbol`
- `module_path`
- `source_path`
- `directive_line`
- `directive_column`
- `handler_line`
- `handler_column`

Duplicate identity is `(method, normalized_path)`.

## Diagnostics

| Code | Meaning |
| --- | --- |
| `FRG001` | malformed directive |
| `FRG002` | unsupported method |
| `FRG003` | missing or invalid path |
| `FRG004` | unknown key or trailing token |
| `FRG005` | duplicate directive on the same handler for the same normalized route |
| `FRG006` | orphan directive |
| `FRG007` | directive would bind to nested handler |
| `FRG008` | duplicate route registration |
| `FRG009` | ambiguous module mapping |
| `FRG010` | invalid module or import path segment |
| `FRG011` | ambiguous generated handler import resolution |
| `FRG012` | unsafe output overwrite |
| `FRG013` | stale or missing output |
| `FRG014` | formatter failure |
| `FRG015` | source changed during generation |
| `FRG016` | incompatible Mojo or Flare version |
| `FRG017` | invalid UTF-8 or unreadable file |
| `FRG018` | output path falls inside scanned inputs without exclusion |

Each diagnostic should include source path, one-based line/column, explanation, and obvious correction text when available.

## Atomic output procedure

1. Scan and validate all inputs
2. Render generated bytes in memory
3. Refuse overwrite unless the existing file contains the generated marker
4. Write a temporary sibling file
5. Format the temporary file
6. Re-read formatted bytes
7. Reconfirm source inputs have not changed
8. Atomically replace the output file

## Generated-file policy

Recommendation: commit generated files.

Reasons:

- supports ordinary Mojo builds without requiring generation during build
- keeps generated route diffs reviewable
- enables CI freshness checks through `check`

Required marker:

```mojo
# Generated by flare-routegen. Do not edit.
# flare-routegen: format=1 renderer=comptime
```

## Test plan

### Unit and parser tests

- valid directives
- malformed directives
- decorators between directive and handler
- multiline signatures
- nested functions
- fake directive text inside strings/comments
- invalid UTF-8
- large files and deep trees

### Golden tests

- exact-byte output for known fixtures
- reversed filesystem enumeration still yields identical bytes
- stable import aliasing and wrapper naming

### CLI tests

- help and version
- exit codes
- overwrite protection
- stale detection
- formatter failure path

### Flare integration tests

- generated compile-time file compiles against pinned Flare
- cross-module handlers compile
- repeated handler registration compiles
- optional in-process request verification with Flare `TestClient`

### Negative cases

- symlink loops
- ambiguous module mapping
- source mutation during scan/generate
- output inside source tree without exclusion

## Packaging strategy

- Prefer a Mojo-native executable
- Start with CLI-only configuration
- Add Pixi tasks for testing, formatting, and generation
- Provide `conda.recipe/recipe.yaml`
- Follow the `heat-url` pattern of pinned commit-based source in recipes
- Pin compiler versions narrowly in CI and packaging

## Rejected alternatives

- real decorators or macros
- general Mojo parser
- runtime `Router` as the primary output form
- Python-first implementation
- config file in v0.1

## Future migration path

If Mojo later gains stable user-defined decorators, retain the internal discovered-route model and replace only the discovery layer. Rendering, diagnostics, CLI semantics, and generated code boundaries can remain stable.

## Ordered roadmap

1. skeleton, pins, and probe harness
2. scanner, diagnostics, and `list`
3. deterministic compile-time renderer
4. `generate`/`check`, atomic output, and formatter integration
5. Flare compile integration
6. packaging, CI, and documentation

## Milestone files

- `specs/milestones/01-skeleton-pins-probes.md`
- `specs/milestones/02-scanner-diagnostics-list.md`
- `specs/milestones/03-module-mapping-and-renderer.md`
- `specs/milestones/04-generate-check-atomic-output.md`
- `specs/milestones/05-flare-integration.md`
- `specs/milestones/06-packaging-ci-docs.md`
