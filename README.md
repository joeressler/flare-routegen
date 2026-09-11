# flare-routegen

Generate deterministic Flare route registrations from structured Mojo comment
directives. User source stays valid Mojo; the tool discovers top-level
`# @flare.route <METHOD> <PATH>` comments and emits compile-time `ComptimeRoute`
glue through public Flare APIs.

This is **not** a Flask-like framework. It does not implement routing, HTTP
behavior, middleware, or application contexts.

## Compatibility

| Component | CI / validation pin | Supported range |
| --- | --- | --- |
| Mojo | `1.0.0` | `>=1.0.0,<1.1.0` |
| Flare | git `main` | API range `>=0.10.0,<0.11.0` |
| Pixi | `0.70.2` | exact in CI |

Flare is a Pixi **git** dependency from `main`. The published pixi-build
package for Flare `v0.10.0` cannot be installed with Pixi `0.70.2`.

The generator CLI does not import Flare. Apps that compile generated routes
must depend on Flare themselves (this workspace already does for tests and
the fixture app).

## Setup

Requires [Pixi](https://pixi.sh/) and a C linker (`gcc` on Linux).

```bash
pixi install
pixi run flare-routegen -- --version
pixi run generate-fixture
pixi run run-fixture
pixi run check-fixture
pixi run test
pixi run fmt
```

`pixi run fmt-check` formats the same paths as `fmt` and fails if git reports
a diff (used by CI).

## Usage

Scan a package and write a generated module (committed next to the app):

```bash
pixi run flare-routegen -- generate --source src --package my_app --output src/my_app/_generated_routes.mojo
pixi run flare-routegen -- check --source src --package my_app --output src/my_app/_generated_routes.mojo
pixi run flare-routegen -- list --source src --package my_app
```

`generate` refuses to overwrite a file that lacks the generated-file marker.
`check` compares exact formatted bytes and exits `1` when the file is stale.
User source files are never rewritten.

### Directives

Place one or more comments immediately before a top-level `def` or `struct`:

```mojo
# @flare.route GET /
def home(req: Request) raises -> Response:
    return ok("home")
```

Typed extractors use Flare's public `Extracted[H]` shape. The generator
registers the struct; it does not parse extractor fields:

```mojo
# @flare.route GET /users/:id
@fieldwise_init
struct GetUser(Copyable, Defaultable, Handler, Movable):
    var id: PathInt["id"]

    def __init__(out self):
        self.id = PathInt["id"]()

    def serve(self, req: Request) raises -> Response:
        return ok("user=" + String(self.id.value))
```

Generated compile-time tables wrap structs as `Extracted[H]().serve(req)`
because `ComptimeRoute` stores a function pointer. Stock middleware
(`RequestId`, `Logger`, `Cors`, ...) wraps `ComptimeRouter[ROUTES]` in
application code.

Mojo does not allow `main()` inside a package. Keep the executable beside
the package (see `examples/fixture_app/src/main.mojo` and `my_app/`).

## Packaging

[`conda.recipe/recipe.yaml`](conda.recipe/recipe.yaml) builds a `flare-routegen`
binary with `mojo build`. In this repository the recipe uses a path source so
CI can build the checkout. A [modular-community](https://github.com/modular/modular-community)
recipe should pin `git` + `rev` the way [heat-url](https://github.com/joeressler/heat-url)
does. The recipe does **not** depend on a Flare conda package.

## Specification

See [`specs/flare-routegen-v0.1-spec.md`](specs/flare-routegen-v0.1-spec.md) for
architecture, directive grammar, diagnostics, and roadmap. Changes are listed
in [`CHANGELOG.md`](CHANGELOG.md).

## Contributing

Human workflow is in [`CONTRIBUTING.md`](CONTRIBUTING.md). Coding-agent notes
are in [`AGENTS.md`](AGENTS.md).
