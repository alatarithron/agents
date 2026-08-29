#!/usr/bin/env bash
# Creates the global per-tool symlinks pointing at the canonical AGENTS.md.
# Idempotent: updates existing symlinks, never overwrites regular files.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANON="$ROOT/AGENTS.md"

link() {
  local linkpath="$1"
  mkdir -p "$(dirname "$linkpath")"
  if [ -L "$linkpath" ]; then
    ln -sfn "$CANON" "$linkpath"
    echo "updated: $linkpath -> $CANON"
  elif [ -e "$linkpath" ]; then
    echo "SKIP (regular file exists, resolve manually): $linkpath"
  else
    ln -s "$CANON" "$linkpath"
    echo "linked:  $linkpath -> $CANON"
  fi
}

link "$HOME/.claude/CLAUDE.md"
link "$HOME/.codex/AGENTS.md"

# Gemini CLI reads GEMINI.md; only wire it if the tool is present.
if [ -d "$HOME/.gemini" ]; then
  link "$HOME/.gemini/GEMINI.md"
fi

# Hermes discovers workspace AGENTS.md natively and ignores other tools'
# global files. Its only global hook is the SOUL.md persona file, so append
# a pointer to it instead of symlinking (a symlink would erase the persona).
if [ -f "$HOME/.hermes/SOUL.md" ]; then
  if grep -qF "$CANON" "$HOME/.hermes/SOUL.md"; then
    echo "ok (pointer present): $HOME/.hermes/SOUL.md"
  else
    printf '\nFollow the user preferences and operating rules in %s. Read that file at the start of any coding or project session.\n' "$CANON" >>"$HOME/.hermes/SOUL.md"
    echo "appended pointer: $HOME/.hermes/SOUL.md"
  fi
fi

echo "done."
