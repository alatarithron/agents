#!/usr/bin/env bash
# Read-only textual comparisons; no fetching, merging, or provenance updates.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:?usage: template-diff.sh <project-dir>}"
DEST="$(cd -- "$DEST" && pwd)"
for relative in .agents .agents/skills .agents/skills/code-simplifier .agents/skills/debugging .agents/skills/pre-commit-review; do
  dir="$DEST/$relative"
  if [ -L "$dir" ] || { [ -e "$dir" ] && [ ! -d "$dir" ]; }; then
    printf 'ERROR: expected a real directory: %s\n' "$dir" >&2
    exit 2
  fi
done
# Prevent partial-clone lazy fetches and replacement objects when reading blobs.
export GIT_NO_LAZY_FETCH=1 GIT_NO_REPLACE_OBJECTS=1
origin="$DEST/.agents/TEMPLATE_ORIGIN"
valid_origin=0
if [ -f "$origin" ] && [ ! -L "$origin" ]; then
  IFS= read -r header < "$origin" || header=''
  if [ "$header" = template-origin-v1 ]; then valid_origin=1; fi
fi
printf 'Text comparison only — not semantic drift, compliance, or an automatic merge.\n'
if [ "$valid_origin" -eq 0 ]; then
  printf 'No baseline manifest (older adoption, missing or unsupported provenance).\n'
fi

compare() {
  local left="$1" right="$2" left_label="$3" right_label="$4" status=0
  diff -u --label "$left_label" --label "$right_label" -- "$left" "$right" || status=$?
  if [ "$status" -gt 1 ]; then exit 2; fi
  if [ "$status" -eq 0 ]; then printf '(identical)\n'; fi
}

report() {
  local relative="$1" source="$2" adopted="$DEST/$1" current="$ROOT/$2"
  local kind path template hash extra blob='' matches=0
  printf '\n=== %s ===\n' "$relative"
  if [ ! -f "$adopted" ] || [ -L "$adopted" ]; then
    printf 'SKIP: adopted document is absent or not a regular, non-symlink file.\n'
    return
  fi
  if [ ! -f "$current" ] || [ -L "$current" ]; then
    printf 'ERROR: current template is not a regular, non-symlink file: %s\n' "$current" >&2
    exit 2
  fi
  if [ "$valid_origin" -eq 1 ]; then
    # Match only fixed paths supplied by this script. Never follow recorded paths.
    while IFS=$'\t' read -r kind path template hash extra; do
      if [ "$kind" = file ] && [ "$path" = "$relative" ] && [ "$template" = "$source" ]; then
        matches=$((matches + 1))
        if [[ -z "$extra" && "$hash" =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ ]]; then blob="$hash"; fi
      fi
    done < "$origin"
  fi
  if [ "$matches" -eq 1 ] && [ -n "$blob" ] && command -v git >/dev/null 2>&1 &&
    [ "$(git -C "$ROOT" cat-file -t "$blob" 2>/dev/null || true)" = blob ]; then
    printf '%s\n' '--- baseline -> adopted (local edits) ---'
    compare <(git -C "$ROOT" cat-file blob "$blob") "$adopted" "baseline/$relative" "adopted/$relative"
    printf '%s\n' '--- baseline -> current template (template changes) ---'
    compare <(git -C "$ROOT" cat-file blob "$blob") "$current" "baseline/$relative" "current/$source"
  else
    printf 'No baseline available for this file (unattributed, invalid, or blob unavailable locally).\n'
  fi
  printf '%s\n' '--- current template -> adopted (customization may be intentional) ---'
  compare "$current" "$adopted" "current/$source" "adopted/$relative"
}
report AGENTS.md templates/AGENTS.project.md
report .agents/PROJECT_MEMORY.md templates/PROJECT_MEMORY.md
report .agents/BOOTSTRAP.md templates/BOOTSTRAP.md
report .agents/skills/README.md templates/skills/README.md
for skill in code-simplifier debugging pre-commit-review; do
  report ".agents/skills/$skill/SKILL.md" "templates/skills/$skill/SKILL.md"
done
# Differences are informational (0); operational errors return nonzero.
