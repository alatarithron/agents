#!/usr/bin/env bash
# Adopts the agent-instructions structure without replacing existing objects.
# Requires trusted, stable source/target directories; not atomic confinement.
# Do not run with elevated privileges or concurrent directory mutation.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:?usage: adopt.sh <project-dir>}"
DEST="$(cd -- "$DEST" && pwd)"

# The shipped skill set is whatever lives under templates/skills/<name>/SKILL.md.
shopt -s nullglob
skills=("$ROOT"/templates/skills/*/SKILL.md)
shopt -u nullglob
if [ "${#skills[@]}" -eq 0 ]; then
  printf 'ERROR: no skill templates under %s/templates/skills\n' "$ROOT" >&2
  exit 1
fi
skills=("${skills[@]%/SKILL.md}")
skills=("${skills[@]##*/}")

# Preflight every directory we write through before making any changes.
directories=(.agents .agents/decisions .agents/skills .github .github/workflows)
templates=(AGENTS.project.md PROJECT_MEMORY.md BOOTSTRAP.md skills/README.md agent-policy.yml)
for skill in "${skills[@]}"; do
  directories+=(".agents/skills/$skill")
  templates+=("skills/$skill/SKILL.md")
done
for relative in "${directories[@]}"; do
  dir="$DEST/$relative"
  if [ -L "$dir" ] || { [ -e "$dir" ] && [ ! -d "$dir" ]; }; then
    printf 'ERROR: expected a real directory, refusing: %s\n' "$dir" >&2
    exit 1
  fi
done
for template in "${templates[@]}"; do
  if [ ! -f "$ROOT/templates/$template" ]; then
    printf 'ERROR: missing template: %s\n' "$ROOT/templates/$template" >&2
    exit 1
  fi
done

created_any=0
records=()
revision=unknown
if command -v git > /dev/null 2>&1; then
  revision="$(git -C "$ROOT" rev-parse --verify HEAD 2> /dev/null)" || revision=unknown
fi
copy() {
  local src="$1" relative="$2" dst="$DEST/$2" blob=unknown
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    printf 'SKIP (exists): %s\n' "$dst"
  else
    # noclobber also protects against an object appearing after the check.
    (
      set -o noclobber
      cat -- "$ROOT/$src" > "$dst"
    )
    created_any=1
    if command -v git > /dev/null 2>&1; then
      blob="$(git -C "$ROOT" hash-object --no-filters -- "$dst" 2> /dev/null)" || blob=unknown
    fi
    records+=("$(printf 'file\t%s\t%s\t%s' "$relative" "$src" "$blob")")
    printf 'created: %s\n' "$dst"
  fi
}

# Parents precede children; plain mkdir refuses an object raced into place.
for relative in "${directories[@]}"; do
  dir="$DEST/$relative"
  if [ -L "$dir" ]; then
    printf 'ERROR: expected a real directory, refusing: %s\n' "$dir" >&2
    exit 1
  fi
  if [ ! -d "$dir" ]; then mkdir -- "$dir"; fi
  if [ -L "$dir" ] || [ ! -d "$dir" ]; then
    printf 'ERROR: expected a real directory, refusing: %s\n' "$dir" >&2
    exit 1
  fi
done
copy templates/AGENTS.project.md AGENTS.md
copy templates/PROJECT_MEMORY.md .agents/PROJECT_MEMORY.md
copy templates/BOOTSTRAP.md .agents/BOOTSTRAP.md
copy templates/skills/README.md .agents/skills/README.md
# ⚠️ The gate, not just the checker. A policy nobody runs is a policy that
# drifts — see the workflow's own header for what that cost. A project not on
# GitHub Actions deletes this file and wires the command elsewhere.
copy templates/agent-policy.yml .github/workflows/agent-policy.yml
for skill in "${skills[@]}"; do
  copy "templates/skills/$skill/SKILL.md" ".agents/skills/$skill/SKILL.md"
done

# ⚠️ **The workflow is pinned on the way in.** `adopt.sh` already knows which
# commit it is copying from — it is the one recorded in TEMPLATE_ORIGIN below —
# and a project whose first push fails on `ref: REPLACE_WITH_…` learns that the
# gate is a nuisance before it learns that it is useful. With no revision to
# pin, the placeholder stays and reads as the instruction it is.
workflow="$DEST/.github/workflows/agent-policy.yml"
if [ "$revision" != unknown ] && [ -f "$workflow" ] && [ ! -L "$workflow" ]; then
  if grep -q 'REPLACE_WITH_THE_ADOPTED_COMMIT' "$workflow"; then
    tmp="$workflow.adopt.$$"
    sed "s/REPLACE_WITH_THE_ADOPTED_COMMIT/$revision/" "$workflow" > "$tmp"
    mv -- "$tmp" "$workflow"
    printf 'pinned: %s -> %s\n' "$workflow" "$revision"
  fi
fi

origin="$DEST/.agents/TEMPLATE_ORIGIN"
if [ -e "$origin" ] || [ -L "$origin" ]; then
  printf 'SKIP (existing provenance is never updated): %s\n' "$origin"
elif [ "${#records[@]}" -gt 0 ]; then
  # Inert tab-separated text. Only documents installed by this run are listed.
  # Hashes describe the copied bytes, including uncommitted template changes.
  (
    set -o noclobber
    {
      printf 'template-origin-v1\nrevision\t%s\n' "$revision"
      printf '%s\n' "${records[@]}"
    } > "$origin"
  )
  printf 'created: %s\n' "$origin"
fi

if [ -e "$DEST/CLAUDE.md" ] || [ -L "$DEST/CLAUDE.md" ]; then
  printf 'SKIP (exists): %s/CLAUDE.md\n' "$DEST"
else
  ln -sT AGENTS.md "$DEST/CLAUDE.md"
  created_any=1
  printf 'linked: %s/CLAUDE.md -> AGENTS.md\n' "$DEST"
fi

if [ -f "$DEST/.gitignore" ] && grep -Eq '(^|/)\.agents' "$DEST/.gitignore"; then
  printf 'WARNING: .agents appears in %s/.gitignore — remove it so the memory is versioned.\n' "$DEST"
fi
if [ "$created_any" -eq 1 ]; then
  printf 'done. Follow %s/.agents/BOOTSTRAP.md; fill project rules and verified memory.\n' "$DEST"
else
  printf 'done. Nothing to create — this project is already adopted.\n'
fi
