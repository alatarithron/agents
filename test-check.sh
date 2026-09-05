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
expect "missing decisions/ with a linked ADR fails" 1 "do not exist"

p="$(fixture)"; rm -rf "$p/.agents/decisions"
printf '# Project memory\n\nNo decisions yet.' > "$p/.agents/PROJECT_MEMORY.md"
expect "missing decisions/ without links warns only" 0 "passed with 1 warning"

p="$(fixture)"; rm "$p/.agents/decisions/001-only-one.md"
printf '# Project memory\n\nNo decisions yet.' > "$p/.agents/PROJECT_MEMORY.md"
expect "empty decisions/ without links completes" 0 "passed with 0 warning"

p="$(fixture)"
printf '# Project memory\n\nNo decisions yet.' > "$p/.agents/PROJECT_MEMORY.md"
expect "unlinked ADR without any links warns" 0 "never referenced"

p="$(fixture)"
printf '\n- [Ghost](decisions/002-ghost.md)' >> "$p/.agents/PROJECT_MEMORY.md"
expect "missing ADR on final unterminated line" 1 "002-ghost"

p="$(fixture)"; cp "$ROOT/templates/PROJECT_MEMORY.md" "$p/.agents/PROJECT_MEMORY.md"
expect "untouched memory template fails" 1 "empty placeholders"

for field in 'Primary goal' 'Explicit non-goals' 'Intended users' \
  'Main components and their responsibilities' 'Important boundaries' 'Data flow' \
  'Supported operating systems' 'Runtime and required versions' 'Package manager' \
  'External services' 'Install' 'Run' 'Test existing suite' 'Lint' 'Type-check' 'Build' \
  'Project-specific naming or structure' 'Error-handling conventions' \
  'API or database conventions' 'Compatibility requirements'; do
  p="$(fixture)"
  printf '\n%s:   ' "$field" >> "$p/.agents/PROJECT_MEMORY.md"
  expect "empty memory field: $field (no newline)" 1 "empty placeholders"
done

for field in 'Purpose' 'Architecture' 'Runtime and package manager' 'Install command' \
  'Run command' 'Test command' 'Lint command' 'Type-check command' \
  'Build command' 'Compatibility requirements'; do
  p="$(fixture)"
  printf '\n- %s:' "$field" >> "$p/AGENTS.md"
  expect "empty legacy AGENTS field: $field" 1 "empty placeholders"
done

p="$(fixture)"
printf '\n## Architecture\n' >> "$p/.agents/PROJECT_MEMORY.md"
expect "empty memory section fails" 1 "empty section"

p="$(fixture)"
printf '\n## Domain language\n\n| Term | Meaning |\n| --- | --- |' >> "$p/.agents/PROJECT_MEMORY.md"
expect "header-only memory table fails" 1 "empty section"

p="$(fixture)"
printf '\n- [Decision title](decisions/NNN-short-title.md)' >> "$p/.agents/PROJECT_MEMORY.md"
expect "placeholder ADR link fails" 1 "template guidance"

p="$(fixture)"
printf '\n- Durable, verified limitations and recurring traps.' >> "$p/.agents/PROJECT_MEMORY.md"
expect "memory guidance without newline fails" 1 "template guidance"

p="$(fixture)"
printf '\n- The invariant a change must never violate, and what to do instead when the task seems to require it.' >> "$p/AGENTS.md"
expect "AGENTS example rule fails" 1 "template guidance"

# A freshly adopted project: decisions/ exists, nothing in it, and the memory
# links nothing. grep finds no link and exits 1; under `set -e` + `pipefail`
# that used to kill check.sh silently before the summary.
p="$(fixture)"; rm "$p/.agents/decisions/001-only-one.md"
sed -i 's/^- \[Only one\].*/- No architectural decisions yet./' "$p/.agents/PROJECT_MEMORY.md"
expect "fresh adoption with no decision links" 0 "0 decision record(s), all cross-referenced"

p="$(fixture)"; echo ".agents/" > "$p/.gitignore"
expect "memory excluded outside git" 1 "must be versioned"

p="$(fixture)"; printf '# /.agents/ is versioned\n!.agents/\n' > "$p/.gitignore"
expect "comments and negations outside git pass" 0 "passed with 0 warning"

p="$(fixture)"; printf '.agents/\n!.agents/\n' > "$p/.gitignore"
expect "ambiguous ignore rules outside git warn" 0 "effective ignore rules cannot be verified"

# Isolate Git from the users configuration without changing their home.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
for pattern in '.agents/' '*.md' '.agents/PROJECT_MEMORY.md' '.agents/decisions/*.md' 'AGENTS.md'; do
  p="$(fixture)"; git -C "$p" init -q
  printf '%s' "$pattern" > "$p/.gitignore"
  expect "git effectively ignores $pattern (no newline)" 1 "must be versioned"
done

p="$(fixture)"; git -C "$p" init -q
printf '# /.agents/ is versioned\n*.md\n!AGENTS.md\n!.agents/PROJECT_MEMORY.md\n!.agents/decisions/*.md\n' > "$p/.gitignore"
expect "git honours negations and comments" 0 "passed with 0 warning"

p="$(fixture)"; git -C "$p" init -q
printf '.agents/\n!.agents/PROJECT_MEMORY.md\n' > "$p/.gitignore"
expect "cannot reinclude a file under an ignored parent" 1 "must be versioned"

p="$(fixture)"; git -C "$p" init -q
git -C "$p" add AGENTS.md .agents
printf '*.md\n' > "$p/.gitignore"
expect "tracked files still checked for ignore rules" 1 "must be versioned"

p="$(fixture)"; git -C "$p" init -q
printf '*.md\n' > "$p/.agents/.gitignore"
expect "nested ignore rules are checked" 1 "must be versioned"

p="$(fixture)"; git -C "$p" init -q
printf '.agents/\n' >> "$p/.git/info/exclude"
expect "git info exclude is checked" 1 "must be versioned"

# Approved skill checks: valid shipped content plus isolated negative cases.
skill_fixture() {
  fixture
  cp -R "$ROOT/templates/skills" "$WORK/p/.agents/skills"
}
p="$(skill_fixture)"
expect "shipped skill index and frontmatter pass" 0 "passed with 0 warning"

p="$(skill_fixture)"; rm "$p/.agents/skills/README.md"
expect "installed skills require an index" 1 "regular non-symlink index"

p="$(skill_fixture)"
sed -i 's|debugging/SKILL.md|missing/SKILL.md|' "$p/.agents/skills/README.md"
expect "broken skill link fails" 1 "not an existing regular non-symlink file"

p="$(skill_fixture)"
sed -i '/^| \[debugging\]/d' "$p/.agents/skills/README.md"
expect "unindexed skill fails" 1 "skill is not indexed"

p="$(skill_fixture)"
sed -i 's|debugging/SKILL.md|../debugging/SKILL.md|' "$p/.agents/skills/README.md"
expect "skill index traversal fails" 1 "unsafe or unsupported skill index target"

p="$(skill_fixture)"
rm "$p/.agents/skills/debugging/SKILL.md"
ln -s "$ROOT/templates/skills/debugging/SKILL.md" "$p/.agents/skills/debugging/SKILL.md"
expect "symlinked skill fails" 1 "non-symlink file"

for field in name description; do
  p="$(skill_fixture)"
  sed -i "/^$field:/d" "$p/.agents/skills/debugging/SKILL.md"
  expect "missing skill $field fails" 1 "missing frontmatter $field"
  p="$(skill_fixture)"
  sed -i "s/^$field:.*/$field: \"\"/" "$p/.agents/skills/debugging/SKILL.md"
  expect "empty skill $field fails" 1 "empty frontmatter field: $field"
done

p="$(skill_fixture)"
sed -i '/^description:/a description: Duplicate.' "$p/.agents/skills/debugging/SKILL.md"
expect "duplicate skill description fails" 1 "duplicate frontmatter field"

p="$(skill_fixture)"
sed -i 's/^name: debugging/name: different/' "$p/.agents/skills/debugging/SKILL.md"
expect "skill name must match directory" 1 "name must match directory"

p="$(skill_fixture)"
printf '%s\n' '---' 'name: debugging' 'description: No body.' '---' > "$p/.agents/skills/debugging/SKILL.md"
expect "empty skill body fails" 1 "empty skill body"

p="$(skill_fixture)"
sed -i '1d' "$p/.agents/skills/debugging/SKILL.md"
expect "skill opening delimiter required" 1 "missing opening"

p="$(skill_fixture)"
printf '%s\n' '---' 'name: debugging' 'description: No closing delimiter.' > "$p/.agents/skills/debugging/SKILL.md"
expect "skill closing delimiter required" 1 "missing closing"

p="$(skill_fixture)"
sed -i '/^version:/a platforms: [linux]\nmetadata:\n  category: development' "$p/.agents/skills/debugging/SKILL.md"
expect "optional structured metadata allowed" 0 "passed with 0 warning"

for ignored in .agents/BOOTSTRAP.md .agents/TEMPLATE_ORIGIN .agents/skills/README.md \
  .agents/skills/debugging/SKILL.md .agents/skills/debugging/scripts/helper.sh; do
  p="$(skill_fixture)"; git -C "$p" init -q
  mkdir -p "$p/.agents/skills/debugging/scripts"
  printf 'Bootstrap fixture\n' > "$p/.agents/BOOTSTRAP.md"
  printf 'template-origin-v1\nrevision\tunknown\n' > "$p/.agents/TEMPLATE_ORIGIN"
  printf '# Helper fixture\n' > "$p/.agents/skills/debugging/scripts/helper.sh"
  printf '%s\n' "$ignored" > "$p/.gitignore"
  expect "new asset ignore detected: $ignored" 1 "$ignored is ignored by git"
done

# Exercise each authoring prompt in the shipped templates independently, so
# one detected placeholder cannot hide another undetected prompt.
for template in PROJECT_MEMORY.md AGENTS.project.md; do
  while IFS= read -r prompt || [ -n "$prompt" ]; do
    p="$(fixture)"
    target="$p/.agents/PROJECT_MEMORY.md"
    [ "$template" != AGENTS.project.md ] || target="$p/AGENTS.md"
    printf '\n%s' "$prompt" >> "$target"
    expect "$template guidance: ${prompt:0:55}" 1 "template guidance"
  done < <(awk '
    FILENAME ~ /AGENTS.project.md$/ {
      if (/^## Repository-specific rules/) rules = 1
      if (rules && NF && !/^#/) print
      next
    }
    /^## Maintenance/ { exit }
    /^> .*Delete every section/ { print; next }
    /^[-A-Za-z]/ && !/:[[:space:]]*$/ { print }
  ' "$ROOT/templates/$template")
done

p="$(fixture)"; : > "$p/.agents/PROJECT_MEMORY.md"
expect "empty memory fails" 1 "no project facts"

p="$(fixture)"
printf '# Project memory' > "$p/.agents/PROJECT_MEMORY.md"
expect "title-only memory fails without newline" 1 "no project facts"

p="$(fixture)"
printf '\n## Domain language\n\n| Term | Meaning |\n| --- | --- |\n| widget | Durable unit. |' >> "$p/.agents/PROJECT_MEMORY.md"
expect "populated memory table passes without newline" 0 "passed with 0 warning"

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

p="$(fixture)"
printf '# Decision\n\n- Status: accepted' > "$p/.agents/decisions/001-only-one.md"
expect "record without a Date (no newline)" 0 "no Date line"

p="$(fixture)"; sed -i 's/^Verificado.*/12 tests green, no date./' "$p/.agents/PROJECT_MEMORY.md"
expect "test baseline without a date" 0 "without a verification date"

p="$(fixture)"; printf -- 'api_key = "hunter2hunter2"\n' >> "$p/.agents/PROJECT_MEMORY.md"
expect "credential in the memory" 1 "possible credential"

p="$(fixture)"
cat >> "$p/.agents/PROJECT_MEMORY.md" <<'ENTRY'
- The list has a filter popover, a sort popover, hover quick actions on each row, an avatar checkbox for multi-select, a chip on every card and a button in the footer.
ENTRY
expect "entry that is UI inventory" 0 "feature inventory"

p="$(fixture)"
cat >> "$p/.agents/PROJECT_MEMORY.md" <<'ENTRY'
- Never do network I/O while holding the DB lock; every batch op refuses a mix of accounts before touching the cache.
ENTRY
expect "invariant is not mistaken for inventory" 0 "passed with 0 warning"

p="$(fixture)"
printf -- '- %s\n' "$(head -c 200 /dev/zero | tr '\0' 'x')" >> "$p/.agents/PROJECT_MEMORY.md"
CASES=$((CASES + 1))
# Captured, not piped: check.sh exits 1 here, and under `pipefail` a pipeline
# would carry that exit code even when grep matched.
out="$(MEM_FAIL=100 "$ROOT/check.sh" "$WORK/p" 2>&1)"; code=$?
if [ "$code" -eq 1 ] && printf '%s' "$out" | grep -qF "over 100 chars"; then
  printf '  ok    %s\n' "threshold honours MEM_FAIL"
else
  printf '  FAIL  %s — expected exit 1 and report containing: over 100 chars (got exit %d)\n' "threshold honours MEM_FAIL" "$code"
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
