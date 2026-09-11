# Probe fixtures

Disposable input corpus for milestone 2 scanner work. These files are **not**
executed by the CLI in milestone 1.

## Probe conclusions frozen here

### Probes 1–3 (Flare public APIs)

- **Probe 1:** compile-time route tables via `ComptimeRoute` / `ComptimeRouter`
  are supported in pinned Flare `v0.10.0`.
- **Probe 2:** a generated module exporting `ROUTES` can be imported by an app.
- **Probe 3:** runtime `Router` registration remains a valid internal fallback,
  not the primary v0.1 renderer.

Evidence lives in the Flare release at `v0.10.0` and in
[`specs/flare-routegen-v0.1-spec.md`](../../../specs/flare-routegen-v0.1-spec.md).

### Probe 4 (annotation scanner)

Association rule: each top-level `# @flare.route <METHOD> <PATH>` directive binds
to the **next top-level** `def` or `struct`, allowing blank lines, ordinary
comments, and top-level decorators between them.

### Probe 5 (determinism)

Identical route inventories must produce byte-identical output when discovery
order differs. Stable sort keys (in order):

1. normalized module path
2. normalized source path
3. directive line
4. method
5. normalized path
6. handler symbol

## Layout

- `association/` — one `.mojo` file per scanner association case
- `determinism/tree_a/` and `determinism/tree_b/` — same routes, different file
  names so filesystem enumeration order would differ without explicit sorting
