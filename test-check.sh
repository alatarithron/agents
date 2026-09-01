#!/usr/bin/env bash
# Tests that check.sh actually bites.
#
#   ./test-check.sh
#
# A check that stops reading its input keeps printing `ok`, which looks exactly
# like a check that works. So every case below builds a project fixture, breaks
# exactly one thing, and asserts that check.sh reports it — plus one case that
# breaks nothing and must stay silent.
#
# Everything happens in a temporary directory. A test that mutates the working
# tree is a test nobody dares run.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FAILED=0
CASES=0

# Builds a project that check.sh passes cleanly.
fixture() {
  local d="$WORK/p"
  rm -rf "$d"
  mkdir -p "$d/.agents/decisions"

  cat > "$d/AGENTS.md" <<'EOF'
# Instructions for AI agents

## Repository-specific information

- Purpose: a fixture.
- Architecture: one file.
- Install command: `true`
- Run command: `true`
- Test command: `true`
EOF

  cat > "$d/.agents/PROJECT_MEMORY.md" <<'EOF'
# Project memory

## Commands

Verificado em 2026-08-24, bash 5.2: `true` (12 tests green).

## Active architectural decisions

- [Only one](decisions/001-only-one.md)
EOF

  cat > "$d/.agents/decisions/001-only-one.md" <<'EOF'
# Architectural decision: only one

- Status: accepted
- Date: 2026-08-24
EOF
  echo "$d"
}

# expect <name> <exit code> <substring the report must contain>
expect() {
  local name="$1" want_code="$2" want="$3" out code
  CASES=$((CASES + 1))
  out="$("$ROOT/check.sh" "$WORK/p" 2>&1)"; code=$?

  if [ "$code" -ne "$want_code" ]; then
    printf '  FAIL  %s — exit %d, expected %d\n' "$name" "$code" "$want_code"
    printf '%s\n' "$out" | sed 's/^/          /'
    FAILED=1
    return
  fi
  if [ -n "$want" ] && ! printf '%s' "$out" | grep -qF -- "$want"; then
    printf '  FAIL  %s — report lacks: %s\n' "$name" "$want"
    printf '%s\n' "$out" | sed 's/^/          /'
    FAILED=1
    return
  fi
  printf '  ok    %s\n' "$name"
}

echo "check.sh"

p="$(fixture)"
expect "clean fixture passes" 0 "passed with 0 warning"

p="$(fixture)"; rm "$p/AGENTS.md"
expect "missing AGENTS.md" 1 "missing"

p="$(fixture)"; rm "$p/.agents/PROJECT_MEMORY.md"
expect "missing PROJECT_MEMORY.md" 1 "missing"

p="$(fixture)"; rm -rf "$p/.agents/decisions"
expect "missing decisions/ warns only" 0 "no decision records yet"

p="$(fixture)"; echo ".agents/" > "$p/.gitignore"
expect "memory excluded from git" 1 "must be versioned"

p="$(fixture)"; printf -- '- Purpose:\n' >> "$p/AGENTS.md"
expect "unfilled template placeholder" 1 "empty placeholders"

p="$(fixture)"; printf -- '- %s\n' "$(head -c 1300 /dev/zero | tr '\0' 'x')" >> "$p/.agents/PROJECT_MEMORY.md"
expect "entry over the hard limit" 1 "over 1200 chars"

p="$(fixture)"; printf -- '- %s\n' "$(head -c 500 /dev/zero | tr '\0' 'x')" >> "$p/.agents/PROJECT_MEMORY.md"
expect "entry over the soft limit warns" 0 "over 400 chars"

p="$(fixture)"; printf -- '- [Ghost](decisions/002-ghost.md)\n' >> "$p/.agents/PROJECT_MEMORY.md"
expect "memory links a missing record" 1 "do not exist"

p="$(fixture)"; printf -- '- Status: accepted\n' > "$p/.agents/decisions/002-orphan.md"
expect "record nobody references" 0 "never referenced"

p="$(fixture)"; sed -i '/^- Status:/d' "$p/.agents/decisions/001-only-one.md"
expect "record without a Status" 0 "no Status line"

p="$(fixture)"; sed -i 's/^Verificado.*/12 tests green, no date./' "$p/.agents/PROJECT_MEMORY.md"
expect "test baseline without a date" 0 "without a verification date"

p="$(fixture)"; printf -- 'api_key = "hunter2hunter2"\n' >> "$p/.agents/PROJECT_MEMORY.md"
expect "credential in the memory" 1 "possible credential"

p="$(fixture)"
printf -- '- %s\n' "$(head -c 200 /dev/zero | tr '\0' 'x')" >> "$p/.agents/PROJECT_MEMORY.md"
CASES=$((CASES + 1))
# Captured, not piped: check.sh exits 1 here, and under `pipefail` a pipeline
# would carry that exit code even when grep matched.
out="$(MEM_FAIL=100 "$ROOT/check.sh" "$WORK/p" 2>&1)"
if printf '%s' "$out" | grep -qF "over 100 chars"; then
  printf '  ok    %s\n' "threshold honours MEM_FAIL"
else
  printf '  FAIL  %s — report lacks: over 100 chars\n' "threshold honours MEM_FAIL"
  printf '%s\n' "$out" | sed 's/^/          /'
  FAILED=1
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "$CASES cases, all passed"
  exit 0
fi
echo "$CASES cases, failures above"
exit 1
