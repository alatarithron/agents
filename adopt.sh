#!/usr/bin/env bash
# Adopts the agent-instructions structure without replacing existing objects.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:?usage: adopt.sh <project-dir>}"
DEST="$(cd -- "$DEST" && pwd)"

# Preflight every directory we write through before making any changes.
directories=(.agents .agents/decisions .agents/skills
  .agents/skills/code-simplifier .agents/skills/debugging .agents/skills/pre-commit-review)
for relative in "${directories[@]}"; do
  dir="$DEST/$relative"
  if [ -L "$dir" ] || { [ -e "$dir" ] && [ ! -d "$dir" ]; }; then
    printf 'ERROR: expected a real directory, refusing: %s\n' "$dir" >&2
    exit 1
  fi
done
templates=(AGENTS.project.md PROJECT_MEMORY.md BOOTSTRAP.md skills/README.md
  skills/code-simplifier/SKILL.md skills/debugging/SKILL.md skills/pre-commit-review/SKILL.md)
for template in "${templates[@]}"; do
  if [ ! -f "$ROOT/templates/$template" ]; then
    printf 'ERROR: missing template: %s\n' "$ROOT/templates/$template" >&2
    exit 1
  fi
done

created_any=0
records=()
revision=unknown
if command -v git >/dev/null 2>&1; then
  revision="$(git -C "$ROOT" rev-parse --verify HEAD 2>/dev/null)" || revision=unknown
fi
copy() {
  local src="$1" relative="$2" dst="$DEST/$2" blob=unknown
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    printf 'SKIP (exists): %s\n' "$dst"
  else
    # noclobber also protects against an object appearing after the check.
    (set -o noclobber; cat -- "$ROOT/$src" > "$dst")
    created_any=1
    if command -v git >/dev/null 2>&1; then
      blob="$(git -C "$ROOT" hash-object --no-filters -- "$dst" 2>/dev/null)" || blob=unknown
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
for skill in code-simplifier debugging pre-commit-review; do
  copy "templates/skills/$skill/SKILL.md" ".agents/skills/$skill/SKILL.md"
done

origin="$DEST/.agents/TEMPLATE_ORIGIN"
if [ -e "$origin" ] || [ -L "$origin" ]; then
  printf 'SKIP (existing provenance is never updated): %s\n' "$origin"
elif [ "${#records[@]}" -gt 0 ]; then
  # Inert tab-separated text. Only documents installed by this run are listed.
  # Hashes describe the copied bytes, including uncommitted template changes.
  (set -o noclobber
    { printf 'template-origin-v1\nrevision\t%s\n' "$revision"
      printf '%s\n' "${records[@]}"
    } > "$origin")
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
