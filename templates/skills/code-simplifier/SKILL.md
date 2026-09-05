---
name: code-simplifier
description: Simplify task changes without changing behavior.
version: 0.1.0
author: Alatar Ithron (alatarithron), Hermes Agent
license: MIT
---

# Scoped code simplification

## When to use

Use for an explicit simplification request, or one bounded pass over implemented task changes before final validation. Do not refactor untouched modules, apply language preferences from another project, or manufacture edits when the code is already clear.

## Procedure

1. Identify the task-owned diff, including new files. Exclude pre-existing work. Read the surrounding contracts and project conventions before proposing changes.
2. Look for concrete maintenance costs: duplicated logic, unnecessary branching, misleading local names, or abstractions that add no useful boundary. Reuse an existing helper only when its contract actually matches.
3. Preserve public interfaces, outputs, ordering, errors, side effects, concurrency behavior, and compatibility. Keep necessary validation and error handling. A smaller diff or fewer lines is not evidence of improvement.
4. Apply only changes whose behavior can be justified as equivalent. If a proposal changes a contract or requires broader redesign, report it separately rather than folding it into cleanup.
5. Run relevant existing tests, lint, type checks, and build after the final edit. Inspect the resulting diff for accidental scope growth. If equivalence remains uncertain, leave the original code and report the uncertainty.

## Pitfalls

- Do not impose React, JavaScript, or another language's conventions on this repository.
- Do not remove error handling, comments explaining invariants, or apparently unused dynamic entry points without evidence.
- Do not repeat cleanup until an arbitrary aesthetic target is reached. One bounded pass is the default; delegation is optional, not mandatory.
- New feature tests still require the user's manual approval unless the current request explicitly overrides that rule.

## Verification

Report significant changes and checks actually executed. State explicitly when no useful simplification was found or behavior could not be verified. This skill does not authorize commits, pushes, dependency installation, or changes beyond the task.
