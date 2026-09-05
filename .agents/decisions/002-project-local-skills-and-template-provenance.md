# Architectural decision: project-local skills and template provenance

- Status: accepted
- Date: 2026-09-04
- Supersedes: none
- Superseded by: none

## Context

Project adoption needs reusable procedures as well as rules and facts. Independent template copies preserve local customization but lose their origin. Global skill stores do not travel with a project, and discovery conventions vary by tool.

## Decision

- Copy a small set of owned, stack-neutral procedures into `.agents/skills/`. Use `SKILL.md` frontmatter and explicit reading instructions in the project `AGENTS.md`; do not claim native discovery in every tool.
- Keep bootstrap guidance separate from routine context. Commands and architecture live in memory, not in a duplicate section of `AGENTS.md`.
- Record immutable, inert provenance only for files actually installed in that adoption. Store source HEAD and per-file blob IDs, not executable paths or full baseline copies.
- Compare templates read-only. If historical blobs cannot be read locally without fetching, disclose the missing baseline and compare current files only. Never silently overwrite local rules.

## Alternatives considered

- Root `.skills/`: separates procedures visually, but adds another top-level convention without universal discovery. `.agents/skills/` groups agent assets and is documented by Codex.
- Global skills only: avoids per-project copies but loses portability and project-specific review.
- Automatic template synchronization: lowers update effort but cannot safely distinguish local policy from stale defaults.
- Vendor the suggested third-party simplifier verbatim: not selected because the reviewed revision declares no license and assumes JavaScript/React conventions. The kit owns a separate implementation of the workflow objective.

## Consequences

Projects carry their own reviewed procedures, and agents load only relevant bodies. Local copies still require manual maintenance; provenance enables comparison, not semantic conflict resolution. Existing manifests remain unchanged on readoption, so files added later may have no recorded baseline.

## Verification

`test-scripts.sh` exercises real template adoption, preservation, provenance and comparison in disposable fixtures. `test-check.sh` validates documentation checks. The CI workflow executes both suites and ShellCheck. Native CLI skill discovery is not exercised by these tests.

## References

- [Usage and provenance format](../../README.md)
- [Portable project instructions](../../templates/AGENTS.project.md)
- [Codex discovery](https://developers.openai.com/codex/skills/)
- [Claude Code discovery](https://code.claude.com/docs/en/skills)
