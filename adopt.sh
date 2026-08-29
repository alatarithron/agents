#!/usr/bin/env bash
# Adopts the agent-instructions structure in a project.
# Idempotent: never overwrites existing files.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:?usage: adopt.sh <project-dir>}"
DEST="$(cd "$DEST" && pwd)"

copy() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    echo "SKIP (exists): $dst"
  else
    cp "$src" "$dst"
    echo "created: $dst"
  fi
}

mkdir -p "$DEST/.agents/decisions"
copy "$ROOT/templates/AGENTS.project.md" "$DEST/AGENTS.md"
copy "$ROOT/templates/PROJECT_MEMORY.md" "$DEST/.agents/PROJECT_MEMORY.md"

if [ -e "$DEST/CLAUDE.md" ] || [ -L "$DEST/CLAUDE.md" ]; then
  echo "SKIP (exists): $DEST/CLAUDE.md"
else
  ln -s AGENTS.md "$DEST/CLAUDE.md"
  echo "linked:  $DEST/CLAUDE.md -> AGENTS.md"
fi

if [ -f "$DEST/.gitignore" ] && grep -Eq '(^|/)\.agents' "$DEST/.gitignore"; then
  echo "WARNING: .agents appears in $DEST/.gitignore — remove it so the memory is versioned."
fi

echo "done. Now fill in:"
echo "  - $DEST/AGENTS.md (Repository-specific information; remove placeholders)"
echo "  - $DEST/.agents/PROJECT_MEMORY.md (verified facts only)"
