# Contributing

Thanks for looking at flare-routegen. [`specs/flare-routegen-v0.1-spec.md`](specs/flare-routegen-v0.1-spec.md)
is the contract. If code and a spec disagree, fix them together in the same
change.

This is a comment-directive generator for Flare, not a Flask-like framework.
Do not add routing, HTTP behavior, middleware, extractors, or application
contexts here. Keep user source valid Mojo; never rewrite it.

## Setup

Requires [Pixi](https://pixi.sh/) and a C linker (`gcc`). Development, CI, and
the conda recipe target **linux-64** only.

```bash
pixi install
pixi run flare-routegen -- --version
pixi run test
pixi run fmt
```

`pixi install` pulls Flare from git `main`. Do not switch that dependency to
the published pixi-build package for Flare `v0.10.0`; it cannot be installed
with Pixi `0.70.2`.

Run one file:

```bash
pixi run mojo run -I src -D ASSERT=all test/test_scan.mojo
```

Flare integration tests also need the fixture on the import path:

```bash
pixi run mojo run -I src -I examples/fixture_app/src -D ASSERT=all test/test_flare_integration.mojo
```

`pixi run test` walks `test/test_*.mojo`. Do not use `mojo test`.

## Day-to-day commands

```bash
pixi run fmt
pixi run fmt-check
pixi run generate-fixture
pixi run check-fixture
pixi run run-fixture
pixi run test
```

`fmt-check` formats the same paths as `fmt` and then runs `git diff --exit-code`
(CI uses this so format is not a silent rewrite). On a dirty work tree it fails
even when format itself is a no-op.

After changing scanner or renderer output, regenerate the fixture and keep
`examples/fixture_app/src/my_app/_generated_routes.mojo` committed:

```bash
pixi run generate-fixture
pixi run check-fixture
```

## Rules that tend to matter

- Directives are `# @flare.route METHOD PATH` on the next top-level `def` or
  `struct`. Do not invent real decorators or a general Mojo parser.
- Compile-time `ComptimeRoute` tables are the primary renderer. Runtime
  `Router` registration is an internal fallback only.
- Typed extractors stay in Flare. Struct handlers register through existing
  `Extracted[H]` APIs. Do not parse extractor fields or emit middleware.
- Mojo does not allow `main()` inside a package. Keep executables beside the
  package (`examples/fixture_app/src/main.mojo` next to `my_app/`).
- The CLI under `src/` does not import Flare. Only generated apps and
  `test/test_flare_integration.mojo` do.
- Pins live in `src/flare_routegen/version.mojo`. `FLARE_RANGE` is the intended
  API range; CI/dev install Flare from git `main`. `FRG016` is spec-only until
  a later milestone.
- Mojo 1.0: `def` only (no `fn`), `comptime` not `alias`,
  `from std.testing import ...`.
- Comments describe purpose, not effect. Reuse existing helpers instead of
  adding parallel scanners, renderers, or CLIs.

New diagnostics need a stable `FRGxxx` code in
`src/flare_routegen/diagnostics.mojo`, a row in the spec catalog, and a test.
Do not reuse or renumber codes.

## Packaging

[`conda.recipe/recipe.yaml`](conda.recipe/recipe.yaml) builds a linux-64 CLI
with `mojo build` (`skip: osx` and `win`). In-repo CI uses `source.path`. A
[modular-community](https://github.com/modular/modular-community) listing needs
the git URL and a full commit SHA instead. The recipe must not depend on a
Flare conda package.

```bash
rattler-build build \
  --recipe conda.recipe/recipe.yaml \
  -c https://conda.modular.com/max \
  -c conda-forge \
  -c https://repo.prefix.dev/modular-community
```

CI also runs this path. Artifact output belongs in `/output/` (gitignored).

## Pull requests

CI (`.github/workflows/ci.yml`) runs `fmt-check`, `test`, `check-fixture`, and
the conda recipe on `ubuntu-latest` with Pixi `0.70.2`. Tests can take tens of
minutes on a cold compiler cache.

Update [`CHANGELOG.md`](CHANGELOG.md) for user-visible behavior. Link the spec
and [`AGENTS.md`](AGENTS.md) when the change is meant for coding agents as well
as humans.

## License

Contributions land under the MIT License. See [`LICENSE`](LICENSE).
