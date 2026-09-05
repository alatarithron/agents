#!/usr/bin/env bash
# All writes are confined to a disposable HOME and fixture repository.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" HERMES_HOME="$TMP/active profile"
mkdir -p "$HOME" "$HERMES_HOME" "$TMP/source/templates" "$TMP/project with spaces"
cp "$ROOT/adopt.sh" "$ROOT/wire.sh" "$TMP/source/"
cp "$ROOT/templates/AGENTS.project.md" "$ROOT/templates/PROJECT_MEMORY.md" "$TMP/source/templates/"
# A deliberately small fixture; not a replacement for the shipped template.
printf '# Bootstrap fixture\n' > "$TMP/source/templates/BOOTSTRAP.md"
SRC="$TMP/source"
mkdir -p "$SRC/templates/skills"
printf '# Skill fixtures\n' > "$SRC/templates/skills/README.md"
for skill in code-simplifier debugging pre-commit-review; do
  mkdir -p "$SRC/templates/skills/$skill"
  printf '# %s fixture\n' "$skill" > "$SRC/templates/skills/$skill/SKILL.md"
done
PROJECT="$TMP/project with spaces"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }
ln -s missing "$PROJECT/AGENTS.md"
bash "$SRC/adopt.sh" "$PROJECT" > "$TMP/log" 2>&1
[[ -L "$PROJECT/AGENTS.md" && ! -e "$PROJECT/AGENTS.md" ]] || fail 'broken symlink preserved'
pass 'adoption preserves broken symlink'
mkdir -p "$TMP/outside" "$TMP/unsafe"
ln -s "$TMP/outside" "$TMP/unsafe/.agents"
if bash "$SRC/adopt.sh" "$TMP/unsafe" > "$TMP/log" 2>&1; then fail 'symlinked .agents accepted'; fi
[[ ! -e "$TMP/outside/decisions" && ! -e "$TMP/unsafe/AGENTS.md" ]] || fail 'unsafe adoption wrote files'
pass 'symlinked .agents rejected before writes'
# Introduce a parent symlink after preflight, at the first mkdir invocation.
mkdir "$TMP/race-bin" "$TMP/race-project" "$TMP/race-outside"
REAL_MKDIR="$(command -v mkdir)"
export REAL_MKDIR RACE_PROJECT="$TMP/race-project" RACE_OUTSIDE="$TMP/race-outside"
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' \
  'ln -s "$RACE_OUTSIDE" "$RACE_PROJECT/.agents"' \
  'exec "$REAL_MKDIR" "$@"' > "$TMP/race-bin/mkdir"
chmod +x "$TMP/race-bin/mkdir"
race_status=0
PATH="$TMP/race-bin:$PATH" bash "$SRC/adopt.sh" "$RACE_PROJECT" > "$TMP/log" 2>&1 || race_status=$?
[[ -L "$RACE_PROJECT/.agents" ]] || fail 'race shim did not introduce symlink'
shopt -s nullglob dotglob
outside_entries=("$RACE_OUTSIDE"/*)
shopt -u nullglob dotglob
[[ ${#outside_entries[@]} -eq 0 ]] || fail 'raced adoption wrote outside target'
[[ "$race_status" -ne 0 ]] || fail 'raced adoption did not fail'
pass 'parent symlink introduced after preflight cannot redirect adoption writes'
[[ -f "$PROJECT/.agents/BOOTSTRAP.md" ]] || fail 'bootstrap missing'
[[ -f "$PROJECT/.agents/TEMPLATE_ORIGIN" ]] || fail 'provenance missing'
if grep -q $'file\tAGENTS.md\t' "$PROJECT/.agents/TEMPLATE_ORIGIN"; then fail 'preexisting file falsely attributed'; fi
cp "$PROJECT/.agents/TEMPLATE_ORIGIN" "$TMP/origin"
printf 'Local memory\n' > "$PROJECT/.agents/PROJECT_MEMORY.md"
bash "$SRC/adopt.sh" "$PROJECT" > "$TMP/log" 2>&1
cmp "$TMP/origin" "$PROJECT/.agents/TEMPLATE_ORIGIN" || fail 'provenance changed on readoption'
[[ "$(< "$PROJECT/.agents/PROJECT_MEMORY.md")" == 'Local memory' ]] || fail 'local file overwritten'
pass 'bootstrap, partial provenance and readoption preservation'
[[ -f "$ROOT/template-diff.sh" ]] || fail 'template-diff.sh missing'
cp "$ROOT/template-diff.sh" "$SRC/"
mkdir "$TMP/legacy"
printf 'Legacy rules\n' > "$TMP/legacy/AGENTS.md"
bash "$SRC/template-diff.sh" "$TMP/legacy" > "$TMP/diff"
grep -q 'not semantic drift' "$TMP/diff" || fail 'comparison caveat missing'
grep -q 'No baseline' "$TMP/diff" || fail 'legacy baseline warning missing'
# Local git blobs provide baselines without any commits or network access.
git -C "$SRC" init -q
for file in "$SRC"/templates/*.md; do git -C "$SRC" hash-object -w -- "$file" >/dev/null; done
mkdir "$TMP/fresh"
bash "$SRC/adopt.sh" "$TMP/fresh" > "$TMP/log"
printf '\nLocal customization\n' >> "$TMP/fresh/AGENTS.md"
printf '\nUpstream addition\n' >> "$SRC/templates/AGENTS.project.md"
cp "$TMP/fresh/.agents/TEMPLATE_ORIGIN" "$TMP/fresh-origin"
bash "$SRC/template-diff.sh" "$TMP/fresh" > "$TMP/diff"
grep -q 'baseline -> adopted' "$TMP/diff" || fail 'local baseline comparison missing'
grep -q 'baseline -> current template' "$TMP/diff" || fail 'upstream baseline comparison missing'
grep -q '+Local customization' "$TMP/diff" || fail 'local change not shown'
grep -q '+Upstream addition' "$TMP/diff" || fail 'template change not shown'
cmp "$TMP/fresh-origin" "$TMP/fresh/.agents/TEMPLATE_ORIGIN" || fail 'diff modified provenance'
# Recorded strings must never be executed, sourced, or used as paths.
# These are literal untrusted bytes, deliberately not shell expansion.
# shellcheck disable=SC2016
printf '$(touch %s)\n' "$TMP/executed" >> "$TMP/fresh/.agents/TEMPLATE_ORIGIN"
bash "$SRC/template-diff.sh" "$TMP/fresh" > "$TMP/diff"
[[ ! -e "$TMP/executed" ]] || fail 'provenance executed'
pass 'read-only template comparison, legacy fallback and local git baselines'
for relative in skills/README.md skills/code-simplifier/SKILL.md skills/debugging/SKILL.md skills/pre-commit-review/SKILL.md; do
  cmp "$SRC/templates/$relative" "$PROJECT/.agents/$relative" || fail "skill missing: $relative"
  grep -qF "$relative" "$PROJECT/.agents/TEMPLATE_ORIGIN" || fail 'skill provenance missing'
done
printf 'Local skill\n' > "$PROJECT/.agents/skills/debugging/SKILL.md"
bash "$SRC/adopt.sh" "$PROJECT" > "$TMP/log"
[[ "$(< "$PROJECT/.agents/skills/debugging/SKILL.md")" = 'Local skill' ]] || fail 'skill overwritten'
for relative in skills skills/debugging skills/code-simplifier skills/pre-commit-review decisions; do
  unsafe="$TMP/unsafe-${relative//\//-}"
  mkdir -p "$unsafe/.agents/$(dirname "$relative")"
  ln -s "$TMP/outside" "$unsafe/.agents/$relative"
  if bash "$SRC/adopt.sh" "$unsafe" > "$TMP/log" 2>&1; then fail "unsafe directory accepted: $relative"; fi
  [[ ! -e "$unsafe/AGENTS.md" ]] || fail 'unsafe skill adoption wrote files'
done
pass 'skill adoption, provenance, preservation and directory safety'
mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.gemini" "$HOME/.hermes"
printf 'Keep Claude\n' > "$HOME/.claude/CLAUDE.md"
ln -s missing "$HOME/.codex/AGENTS.md"
mkdir "$HOME/.gemini/GEMINI.md"
printf 'Default persona\n' > "$HOME/.hermes/SOUL.md"
printf 'Active persona\n' > "$HERMES_HOME/SOUL.md"
bash "$SRC/wire.sh" > "$TMP/log"
[[ "$(< "$HOME/.hermes/SOUL.md")" = 'Default persona' ]] || fail 'inactive Hermes profile modified'
grep -qF "$SRC/AGENTS.md" "$HERMES_HOME/SOUL.md" || fail 'active Hermes pointer missing'
cp "$HERMES_HOME/SOUL.md" "$TMP/soul"
bash "$SRC/wire.sh" > "$TMP/log"
cmp "$TMP/soul" "$HERMES_HOME/SOUL.md" || fail 'persona changed on rewiring'
[[ "$(< "$HOME/.claude/CLAUDE.md")" = 'Keep Claude' ]] || fail 'regular config overwritten'
[[ "$(readlink "$HOME/.codex/AGENTS.md")" = "$SRC/AGENTS.md" ]] || fail 'broken config symlink not updated'
[[ -d "$HOME/.gemini/GEMINI.md" && ! -L "$HOME/.gemini/GEMINI.md" ]] || fail 'directory config replaced'
pass 'wire profile isolation, idempotence and existing-object preservation'
# The fallback home is used only when no active profile is supplied.
env -u HERMES_HOME bash "$SRC/wire.sh" > "$TMP/log"
grep -qF "$SRC/AGENTS.md" "$HOME/.hermes/SOUL.md" || fail 'default Hermes pointer missing'
mkdir -p "$TMP/objects/.agents/BOOTSTRAP.md" "$TMP/objects/AGENTS.md" "$TMP/objects/CLAUDE.md"
ln -s missing "$TMP/objects/.agents/PROJECT_MEMORY.md"
ln -s missing "$TMP/objects/.agents/TEMPLATE_ORIGIN"
bash "$SRC/adopt.sh" "$TMP/objects" > "$TMP/log"
[[ -d "$TMP/objects/AGENTS.md" && -d "$TMP/objects/CLAUDE.md" && -d "$TMP/objects/.agents/BOOTSTRAP.md" ]] || fail 'existing directory replaced'
[[ -L "$TMP/objects/.agents/PROJECT_MEMORY.md" && ! -e "$TMP/objects/.agents/PROJECT_MEMORY.md" ]] || fail 'memory broken symlink replaced'
[[ -L "$TMP/objects/.agents/TEMPLATE_ORIGIN" && ! -e "$TMP/objects/.agents/TEMPLATE_ORIGIN" ]] || fail 'provenance broken symlink replaced'
pass 'existing document directories and broken memory/provenance links preserved'
mkdir -p "$TMP/broken-parent"
ln -s missing "$TMP/broken-parent/.agents"
if bash "$SRC/adopt.sh" "$TMP/broken-parent" > "$TMP/log" 2>&1; then fail 'broken .agents symlink accepted'; fi
if bash "$SRC/template-diff.sh" "$TMP/unsafe-skills" > "$TMP/log" 2>&1; then fail 'diff followed skills symlink'; fi
bash "$SRC/template-diff.sh" "$PROJECT" > "$TMP/diff"
grep -q '+Local skill' "$TMP/diff" || fail 'skill comparison missing'
# Simulate an archive install with Git absent, retaining only required utilities.
mkdir "$TMP/no-git-bin" "$TMP/no-git-project"
for tool in bash dirname mkdir cat ln grep diff; do ln -s "$(command -v "$tool")" "$TMP/no-git-bin/$tool"; done
PATH="$TMP/no-git-bin" bash "$SRC/adopt.sh" "$TMP/no-git-project" > "$TMP/log"
grep -q $'revision\tunknown' "$TMP/no-git-project/.agents/TEMPLATE_ORIGIN" || fail 'gitless revision missing'
PATH="$TMP/no-git-bin" bash "$SRC/template-diff.sh" "$TMP/no-git-project" > "$TMP/diff"
grep -q 'No baseline available' "$TMP/diff" || fail 'gitless diff fallback missing'
pass 'broken parents, skill comparison and optional Git'
# Exercise the actual shipped templates too, not only tiny test fixtures.
mkdir "$TMP/shipped-project"
bash "$ROOT/adopt.sh" "$TMP/shipped-project" > "$TMP/log"
for relative in BOOTSTRAP.md PROJECT_MEMORY.md skills/README.md skills/code-simplifier/SKILL.md skills/debugging/SKILL.md skills/pre-commit-review/SKILL.md; do
  cmp "$ROOT/templates/$relative" "$TMP/shipped-project/.agents/$relative" || fail "shipped template mismatch: $relative"
done
bash "$ROOT/template-diff.sh" "$TMP/shipped-project" > "$TMP/diff"
revision="$(git -C "$ROOT" rev-parse --verify HEAD 2>/dev/null)" || revision=unknown
grep -qxF "$(printf 'revision\t%s' "$revision")" "$TMP/shipped-project/.agents/TEMPLATE_ORIGIN" || fail 'source revision mismatch'
while IFS=$'\t' read -r kind relative source blob; do
  [[ "$kind" = file ]] || continue
  expected="$(git -C "$ROOT" hash-object --no-filters -- "$ROOT/$source")"
  [[ "$blob" = "$expected" ]] || fail "source blob mismatch: $relative"
done < "$TMP/shipped-project/.agents/TEMPLATE_ORIGIN"
pass 'shipped template integration'
# Shipped skills intentionally use simple, single-line YAML scalar fields.
for skill in code-simplifier debugging pre-commit-review; do
  awk -v name="$skill" '
    NR == 1 { if ($0 != "---") exit 1; next }
    $0 == "---" && !closed { closed = 1; next }
    !closed && $0 == "name: " name { named = 1 }
    !closed && /^description: .+/ { described = 1 }
    closed && /[^[:space:]]/ { body = 1 }
    END { if (!closed || !named || !described || !body) exit 1 }
  ' "$ROOT/templates/skills/$skill/SKILL.md" || fail "invalid shipped skill: $skill"
done
pass 'shipped skill frontmatter and bodies'
# Never append through a persona symlink into another profile or external file.
printf 'External persona\n' > "$TMP/external-soul"
mkdir "$TMP/linked-profile"
ln -s "$TMP/external-soul" "$TMP/linked-profile/SOUL.md"
HERMES_HOME="$TMP/linked-profile" bash "$SRC/wire.sh" > "$TMP/log"
[[ "$(< "$TMP/external-soul")" = 'External persona' ]] || fail 'wire followed persona symlink'
pass 'symlinked persona preserved without touching its target'
