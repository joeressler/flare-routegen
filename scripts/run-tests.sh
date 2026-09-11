#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

shopt -s nullglob
tests=(test/test_*.mojo)
if [[ ${#tests[@]} -eq 0 ]]; then
    echo "No test files found under test/test_*.mojo" >&2
    exit 1
fi

for test_file in "${tests[@]}"; do
    echo "==> ${test_file}"
    mojo run -I src -D ASSERT=all "$test_file"
done

echo "All tests passed."
