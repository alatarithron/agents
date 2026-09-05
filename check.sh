#!/usr/bin/env bash
# Checks a project's agent-instruction files against the policy.
# Read-only: reports, never edits. Exit 1 on error, 0 on warnings only.
#
#   ./check.sh <project-dir>
#
# Thresholds can be overridden:
#   MEM_WARN=400 MEM_FAIL=1200 ./check.sh <project-dir>
set -euo pipefail

DEST="${1:?usage: check.sh <project-dir>}"
DEST="$(cd "$DEST" && pwd)"
MEM_WARN="${MEM_WARN:-400}"
MEM_FAIL="${MEM_FAIL:-1200}"

errors=0
warnings=0

indent() {
  while IFS= read -r l || [ -n "$l" ]; do
    if [ -n "$l" ]; then printf '        %s\n' "$l"; fi
  done
}
err()  { echo "FAIL: $*"; errors=$((errors + 1)); }
warn() { echo "WARN: $*"; warnings=$((warnings + 1)); }
ok()   { echo "ok:   $*"; }

AGENTS="$DEST/AGENTS.md"
MEM="$DEST/.agents/PROJECT_MEMORY.md"
DECISIONS="$DEST/.agents/decisions"
SKILLS="$DEST/.agents/skills"

# Minimal SKILL.md checks, not a YAML parser: exact --- delimiter lines and
# unique top-level name/description with single-line plain or simply quoted
# values. Required fields do not support escapes, block scalars or collections.
# Other metadata is not validated, including nested mappings and arrays.
# CRLF is accepted. Body means at least one nonblank line.
check_skill() {
  local file="$1" name="$2" issues
  if ! issues=$(awk -v expected="$name" '
    function trim(s) {
      sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s
    }
    function fail(s) { print s; bad = 1 }
    { sub(/\r$/, "") }
    NR == 1 {
      if ($0 != "---") { fail("missing opening --- delimiter"); exit }
      next
    }
    !closed && $0 == "---" { closed = 1; next }
    !closed {
      if ($0 !~ /^(name|description):/) next
      if ($0 !~ /^(name|description):[ \t]/ &&
          $0 !~ /^(name|description):$/) {
        fail("unsupported frontmatter line " NR); next
      }
      key = $0; sub(/:.*/, "", key)
      if (seen[key]++) fail("duplicate frontmatter field: " key)
      value = $0; sub(/^[^:]+:/, "", value); value = trim(value)
      quote = substr(value, 1, 1)
      if (quote == "\042" || quote == "\047") {
        if (length(value) < 2 || substr(value, length(value), 1) != quote) {
          fail("unsupported quoted scalar: " key); next
        }
        value = substr(value, 2, length(value) - 2)
        if (index(value, quote) || index(value, "\\")) {
          fail("unsupported scalar escape: " key); next
        }
      } else {
        sub(/[ \t]+#.*/, "", value)
        if (value ~ /^#/) value = ""
        if ((value != "" && index("]}>|&*!{[?,@`\042\047", substr(value, 1, 1))) ||
            value ~ /:[ \t]/ || value ~ /^[-?:]([ \t]|$)/) {
          fail("unsupported scalar: " key); next
        }
        if (value == "~" || tolower(value) == "null") value = ""
      }
      value = trim(value)
      if (key == "name" || key == "description") {
        if (value == "") fail("empty frontmatter field: " key)
        if (key == "name" && value != expected) fail("name must match directory: " expected)
      }
      next
    }
    /[^ \t]/ { body = 1 }
    END {
      if (!closed) fail("missing closing --- delimiter")
      if (!seen["name"]) fail("missing frontmatter name")
      if (!seen["description"]) fail("missing frontmatter description")
      if (!body) fail("empty skill body")
      exit bad
    }
  ' "$file"); then
    err "$file has invalid skill frontmatter or body:"
    printf '%s\n' "$issues" | indent
  fi
}

# --- structure ---------------------------------------------------------------
[ -f "$AGENTS" ] || err "missing $AGENTS"
[ -f "$MEM" ]    || err "missing $MEM"
[ -d "$DECISIONS" ] || warn "missing $DECISIONS (no decision records yet)"

if command -v git >/dev/null 2>&1 && git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Ask Git about effective rules (including parent/nested ignore files,
  # exclusions and negations), even for files already tracked in the index.
  paths=(AGENTS.md .agents/PROJECT_MEMORY.md .agents/decisions/)
  if [ -d "$DECISIONS" ]; then
    while IFS= read -r -d '' path; do
      paths+=("${path#"$DEST/"}")
    done < <(find "$DECISIONS" -type f -name '*.md' -print0)
  fi
  for path in .agents/BOOTSTRAP.md .agents/TEMPLATE_ORIGIN; do
    if [ -e "$DEST/$path" ] || [ -L "$DEST/$path" ]; then paths+=("$path"); fi
  done
  if [ -e "$SKILLS" ] || [ -L "$SKILLS" ]; then
    paths+=(.agents/skills)
    # Do not follow symlinks; include directories, dotfiles and helpers, not
    # just Markdown. A symlinked .agents parent is rejected below, not walked.
    if [ -d "$SKILLS" ] && [ ! -L "$SKILLS" ] && [ ! -L "$DEST/.agents" ]; then
      while IFS= read -r -d '' path; do
        paths+=("${path#"$DEST/"}")
      done < <(find "$SKILLS" -mindepth 1 -print0)
    fi
  fi
  for path in "${paths[@]}"; do
    ignore_status=0
    git -C "$DEST" check-ignore --no-index -q -- "$path" || ignore_status=$?
    case "$ignore_status" in
      0) err "$path is ignored by git — the memory must be versioned" ;;
      1) ;;
      *) err "git check-ignore could not verify $path" ;;
    esac
  done
elif [ -f "$DEST/.gitignore" ]; then
  # Outside Git, only reject unambiguous whole-directory exclusions without
  # negations. Do not pretend to implement Git glob/precedence semantics.
  if grep -Eq '^/?\.agents/?[[:space:]]*$' "$DEST/.gitignore" &&
     ! grep -q '^!' "$DEST/.gitignore"; then
    err ".agents is in .gitignore — the memory must be versioned"
  elif grep -Eq '^[^#![:space:]]' "$DEST/.gitignore"; then
    warn "outside a git work tree: effective ignore rules cannot be verified"
  fi
fi

# --- optional project skills -------------------------------------------------
# Legacy projects without skills remain valid. If installed, the index is a
# regular file and each skill lives exactly one directory below skills/.
if [ -e "$SKILLS" ] || [ -L "$SKILLS" ]; then
  if [ -L "$DEST/.agents" ] || [ -L "$SKILLS" ] || [ ! -d "$SKILLS" ]; then
    err ".agents/skills must be a real directory under a non-symlink .agents"
  else
    indexed=()
    if [ -L "$SKILLS/README.md" ] || [ ! -f "$SKILLS/README.md" ]; then
      err ".agents/skills/README.md must be a regular non-symlink index"
    else
      # Limited Markdown: literal single-line [label](destination), no nested
      # brackets/parentheses, titles, escapes, reference links or angle wrappers.
      # Scan even code/comments; keep examples out of this small index. External
      # scheme URLs and fragment-only links are ignored. Every other target must
      # be exactly <name>/SKILL.md, with an ASCII alphanumeric-leading name
      # containing only letters, digits, underscores and hyphens. No decoding or
      # normalization: traversal, absolute paths, queries and fragments fail.
      link_pattern='\[[^][]*\]\(([^)]*)\)'
      target_pattern='^[a-zA-Z0-9][a-zA-Z0-9_-]*/SKILL\.md$'
      external_pattern='^[a-zA-Z][a-zA-Z0-9+.-]*:'
      while IFS= read -r line || [ -n "$line" ]; do
        while [[ "$line" =~ $link_pattern ]]; do
          match="${BASH_REMATCH[0]}"
          target="${BASH_REMATCH[1]}"
          line="${line#*"$match"}"
          if [[ "$target" =~ $external_pattern || "$target" == \#* ]]; then continue; fi
          if [[ ! "$target" =~ $target_pattern ]]; then
            err "unsafe or unsupported skill index target: $target (expected <name>/SKILL.md)"
            continue
          fi
          name="${target%/SKILL.md}"
          if [ -L "$SKILLS/$name" ] || [ ! -d "$SKILLS/$name" ] ||
             [ -L "$SKILLS/$target" ] || [ ! -f "$SKILLS/$target" ]; then
            err "skill index target is not an existing regular non-symlink file: $target"
            continue
          fi
          indexed+=("$target")
        done
      done < "$SKILLS/README.md"
    fi
    # GNU find does not follow directory symlinks. Reject top-level directory
    # and dangling symlinks that could conceal a skill; never read through them.
    while IFS= read -r -d '' path; do
      if [ -d "$path" ] || [ ! -e "$path" ]; then
        err "symlink is not a supported skill directory: ${path#"$SKILLS/"}"
      fi
    done < <(find "$SKILLS" -mindepth 1 -maxdepth 1 -type l ! -name README.md -print0)
    while IFS= read -r -d '' path; do
      target="${path#"$SKILLS/"}"
      if [[ ! "$target" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*/SKILL\.md$ ]]; then
        err "skill must live at .agents/skills/<name>/SKILL.md: $target"
        continue
      fi
      if [ -L "$path" ] || [ ! -f "$path" ]; then
        err "skill must be a regular non-symlink file: $target"
        continue
      fi
      found=0
      for link in "${indexed[@]}"; do
        if [ "$link" = "$target" ]; then found=1; break; fi
      done
      if [ "$found" -eq 0 ]; then err "skill is not indexed in .agents/skills/README.md: $target"; fi
      check_skill "$path" "${target%/SKILL.md}"
    done < <(find "$SKILLS" -mindepth 1 -name SKILL.md -print0)
  fi
fi

[ "$errors" -eq 0 ] || { echo; echo "$errors error(s), $warnings warning(s)"; exit 1; }

# --- placeholders left behind ------------------------------------------------
# Include legacy AGENTS fields: adopted copies do not change with the template.
fields='Purpose|Architecture|Runtime and package manager|Install command|Run command|Test command|Lint command|Type-check command|Build command|Compatibility requirements'
fields+='|Primary goal|Explicit non-goals|Intended users|Main components and their responsibilities|Important boundaries|Data flow|Supported operating systems|Runtime and required versions|Package manager|External services|Install|Run|Test existing suite|Lint|Type-check|Build|Project-specific naming or structure|Error-handling conventions|API or database conventions'
# These are authoring prompts/examples, not durable instructions such as the
# memory introduction or Maintenance rule. Match whole-line prefixes only.
guidance='Replace this section with actual project details'
guidance+='|Add a line for anything an agent would otherwise get wrong:'
guidance+='|Hard rules this repository imposes on top of everything above\.'
guidance+='|- The invariant a change must never violate,'
guidance+='|- Where secrets, keys, or credentials live in this project,'
guidance+='|- The concurrency, transaction, or I/O rule that is not visible'
guidance+='|- The security boundary that must not be relaxed'
guidance+='|- The question to ask before a new feature,'
guidance+='|- Where architectural decisions are recorded,'
guidance+='|> \*\*Delete every section you cannot fill with a verified fact\.'
guidance+='|Keep this to what is not obvious from the directory layout\.'
guidance+='|Only terms whose meaning is specific to this project\.'
guidance+='|- Business or data rules that must always hold;'
guidance+='|Skip whatever the manifest, lockfile, or version file already states'
guidance+='|Only list commands actually executed and verified in this repository\.'
guidance+='|Do not duplicate what a formatter, linter, or compiler already enforces\.'
guidance+='|Never include credentials or real production payloads\.'
guidance+='|- \[Decision title\]\(decisions/NNN-short-title\.md\)'
guidance+='|Detailed context, alternatives, and consequences belong in the decision record,'
guidance+='|- Durable, verified limitations and recurring traps\.'
guidance+='|- Not a task list\.'
guidance+='|- Pointers to documents a newcomer would not find on their own\.'
for doc in "$AGENTS" "$MEM"; do
  if grep -qE "^[[:space:]]*(- )?($fields):[[:space:]]*$" "$doc"; then
    err "$doc still has empty placeholders from the template"
  else
    ok "${doc##*/} has no empty template placeholders"
  fi
  if grep -qE "^[[:space:]]*($guidance)" "$doc"; then
    err "$doc still carries template guidance or example entries — replace or remove them"
  fi
done

# Deleted sections are fine; retained sections need actual content. Markdown
# headings, empty fences and header-only tables do not constitute project facts.
empty_sections=$(awk '
  function finish() { if (section != "" && !content) print section }
  /^## / { finish(); section = $0; content = 0; next }
  /^# / { next }
  /^[[:space:]]*$/ || /^[[:space:]]*```/ { next }
  /^[[:space:]]*\|[[:space:]:|-]+$/ { next }
  /^\| Term \| Meaning \|$/ { next }
  /^\| Integration \| Purpose \| Contract or documentation \| Failure considerations \|$/ { next }
  { content = 1 }
  END { finish() }
' "$MEM")
if [ -n "$empty_sections" ]; then
  err "$MEM has an empty section — fill it or remove it:"
  printf '%s\n' "$empty_sections" | indent
fi
if ! grep -qE '^[[:space:]]*[^#[:space:]]' "$MEM"; then
  err "$MEM has no project facts"
fi

# --- entry form (policy: one fact with a pointer, ~300 chars) ----------------
long_warn=$(awk -v n="$MEM_WARN" 'length($0) > n' "$MEM" | wc -l)
long_fail=$(awk -v n="$MEM_FAIL" 'length($0) > n' "$MEM" | wc -l)

if [ "$long_fail" -gt 0 ]; then
  err "$long_fail memory line(s) over $MEM_FAIL chars — split into decisions/ or module docs"
  awk -v n="$MEM_FAIL" 'length($0) > n {printf "        line %d: %d chars | %.60s...\n", NR, length($0), $0}' "$MEM"
elif [ "$long_warn" -gt 0 ]; then
  warn "$long_warn memory line(s) over $MEM_WARN chars"
else
  ok "every memory entry is within $MEM_WARN chars"
fi

# --- feature inventory (policy: what the UI does today is read from the code) -
# Heuristic and deliberately conservative: an entry naming several interface
# widgets at once is describing what the screen has, not what is true about the
# project. It warns, never fails — only a reader can tell the two apart.
inventory=$(awk '
  {
    line = tolower($0)
    n = 0
    split("popover tooltip chevron checkbox dropdown hover click drag chip badge button toolbar sidebar modal placeholder scrollbar", w, " ")
    for (i in w) if (index(line, w[i]) > 0) n++
    if (n >= 4) printf "        line %d: %d widget words | %.60s...\n", NR, n, $0
  }' "$MEM")

if [ -n "$inventory" ]; then
  warn "$(printf '%s' "$inventory" | grep -c .) entry/entries read like feature inventory — what the UI has today is read from the code, not the memory"
  printf '%s\n' "$inventory"
else
  ok "no entry reads like feature inventory"
fi

# --- decision records: referential integrity ---------------------------------
files=''
if [ -d "$DECISIONS" ]; then
  files=$(find "$DECISIONS" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | sort)
fi
# No matches is normal; grep status 1 must not abort under pipefail.
linked=$( { grep -oE 'decisions/[0-9]{3}-[a-z0-9-]+\.md' "$MEM" || [ "$?" -eq 1 ]; } | sed 's|decisions/||;s|\.md$||' | sort -u)

orphans=$(comm -23 <(echo "$files") <(echo "$linked") | grep -v '^$' || true)
broken=$(comm -13 <(echo "$files") <(echo "$linked") | grep -v '^$' || true)

if [ -n "$broken" ]; then
  err "memory links to decision records that do not exist:"
  echo "$broken" | indent
fi
if [ -n "$orphans" ]; then
  warn "decision records never referenced from the memory:"
  echo "$orphans" | indent
fi
if [ -z "$broken$orphans" ]; then
  ok "$(printf '%s\n' "$files" | awk 'NF {n++} END {print n+0}') decision record(s), all cross-referenced"
fi

# a record without Status/Date is not usable later
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -q '^- Status:' "$DECISIONS/$f.md" || warn "$f.md has no Status line"
  grep -q '^- Date:'   "$DECISIONS/$f.md" || warn "$f.md has no Date line"
done <<< "$files"

# --- baselines must carry a date (policy: baseline vs run result) ------------
if grep -qiE '(tests? (green|passing)|testes verdes|[0-9]+ (tests?|testes))' "$MEM"; then
  if grep -qiE '(verified|verificado)[^.]{0,40}20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$MEM"; then
    ok "test baseline carries a verification date"
  else
    warn "the memory states a test count without a verification date — a baseline without a date is a run result"
  fi
fi

# --- secrets -----------------------------------------------------------------
if grep -rInE '(password|secret|api[_-]?key|token)\s*[:=]\s*["'"'"'][^"'"'"']{8,}' "$AGENTS" "$MEM" >/dev/null 2>&1; then
  err "possible credential in AGENTS.md or PROJECT_MEMORY.md"
else
  ok "no credential-shaped strings in the instruction files"
fi

echo
if [ "$errors" -gt 0 ]; then
  echo "$errors error(s), $warnings warning(s)"
  exit 1
fi
echo "passed with $warnings warning(s)"
