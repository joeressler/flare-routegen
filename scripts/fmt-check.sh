#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mojo format src test/test_*.mojo test/fixtures/module_map test/fixtures/app_basic \
    test/fixtures/app_invalid test/fixtures/probes examples

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "fmt-check requires a git work tree" >&2
    exit 1
fi

git diff --exit-code
