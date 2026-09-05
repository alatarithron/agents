#!/usr/bin/env bash
# Single fail-fast entry point for local and CI validation of this kit.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$ROOT"

if ! command -v shellcheck >/dev/null 2>&1; then
  printf '%s\n' 'ERROR: ShellCheck is required; no checks were run.' >&2
  exit 127
fi
printf '%s\n' '== Shell syntax =='
for script in ./*.sh; do bash -n "$script"; done
printf '%s\n' '== ShellCheck =='
shellcheck ./*.sh
printf '%s\n' '== Documentation check suite =='
./test-check.sh
printf '%s\n' '== Isolated adoption and wiring suite =='
./test-scripts.sh
printf '%s\n' '== Repository policy =='
./check.sh .
printf '%s\n' 'All validation gates passed.'
