---
name: pre-commit-review
description: Review task changes before an authorized commit.
version: 0.1.0
author: Alatar Ithron (alatarithron), Hermes Agent
license: MIT
---

# Pre-commit review

## When to use

Use before a user-authorized commit or when explicitly asked to review changes. Reviewing does not grant permission to commit or push.

## Procedure

1. Inventory the initial and final diff, staged changes, and new files. Identify task-owned changes; preserve and exclude unrelated work. Review actual new file contents, not only tracked diffs.
2. Prioritize data loss or disclosure, authorization flaws, functional regressions, error handling, concurrency, compatibility, and missing relevant validation. Report location, impact, evidence, and a concrete correction; omit cosmetic preferences.
3. Inspect for secrets without exposing their values. Check boundary validation and external side effects. Inspect scripts and configuration as executable behavior, not harmless documentation.
4. Run relevant existing tests, lint, type checks, and build after the last edit. Compare pre-existing failures using recorded baseline evidence or an isolated checkout, never automatic stash/reset. An unavailable check is unverified, not passed.
5. If review finds a defect, fix only within the authorized scope and rerun affected checks. Use independent read-only review for consequential changes when available; delegate only authorized data and file scope.
6. Before committing, inspect the exact staged diff and stage named paths only. Follow the repository's commit format. Push only with separate authorization, then verify the remote commit and required CI results.

## Pitfalls

- Do not weaken tests, skip hooks, or hide failures to satisfy a green gate.
- Do not create feature-specific tests before the user's manual approval unless explicitly authorized.
- Avoid automatic cleanup, rewriting history, or removing another contributor's work.

## Verification

A passing review means no unresolved blocking findings and relevant checks passed, with limitations disclosed. A successful push is not a completed CI run. Report the actual commit and remote evidence only after verification.
