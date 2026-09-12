#!/usr/bin/env bash
# Single fail-fast entry point for local and CI validation of this kit.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$ROOT"

# ⚠️ **Nothing here degrades to a skip.** A gate that quietly stands down when
# its tool is missing prints no failure, and "no failure" reads exactly like
# "passed" in a log nobody opens twice. Every tool is required, and an absent
# one stops the run before a single check pretends to have happened.
if ! command -v shellcheck > /dev/null 2>&1; then
  printf '%s\n' 'ERROR: ShellCheck is required; no checks were run.' >&2
  exit 127
fi
# Prettier (with `prettier-plugin-sh`) formats BOTH the shell and the markdown;
# markdownlint reads the markdown Prettier cannot see. They are npm tools, and
# that is the only reason this shell-and-markdown kit carries a `package.json`.
for tool in prettier markdownlint-cli2; do
  if [ ! -x "$ROOT/node_modules/.bin/$tool" ]; then
    printf 'ERROR: %s is required; run bun install first. No checks were run.\n' "$tool" >&2
    exit 127
  fi
done
printf '%s\n' '== Shell syntax =='
for script in ./*.sh; do bash -n "$script"; done
printf '%s\n' '== ShellCheck =='
shellcheck ./*.sh
printf '%s\n' '== Formatting (.sh and .md) =='
./node_modules/.bin/prettier --check .
printf '%s\n' '== Markdown =='
./node_modules/.bin/markdownlint-cli2
printf '%s\n' '== Documentation check suite =='
./test-check.sh
printf '%s\n' '== Isolated adoption and wiring suite =='
./test-scripts.sh
printf '%s\n' '== Repository policy =='
./check.sh .
printf '%s\n' 'All validation gates passed.'
