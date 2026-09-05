---
name: debugging
description: Investigate failures before changing code.
version: 0.1.0
author: Alatar Ithron (alatarithron), Hermes Agent
license: MIT
---

# Evidence-first debugging

## When to use

Use for a reproducible bug, failing check, unexpected runtime behavior, or a regression. Do not use it to invent requirements for an unimplemented feature.

## Procedure

1. Capture expected versus actual behavior, a minimal reproduction, relevant environment, and the exact failure. Redact private data; do not copy credentials or production payloads into reports.
2. Establish the failure boundary by reading callers, definitions, configuration, and relevant changes. Distinguish an application defect from an environment or dependency failure.
3. Form a falsifiable hypothesis. Run the smallest safe experiment that can distinguish it from alternatives; do not change several independent variables at once.
4. Correct the cause at the narrowest appropriate boundary. Preserve unrelated behavior and pre-existing work. Never disable validation or swallow errors to produce a green result.
5. Repeat the original reproduction and relevant existing checks. Add a regression test when authorized by the project's bug-fix policy; do not bypass approval for new feature behavior.

## Pitfalls

- A retry that happens to pass does not establish the cause of an intermittent failure.
- Do not claim a service was exercised when only its mock ran.
- Stop repeating a failed approach after two attempts; use new evidence or report the blocker.

## Verification

Identify the supported cause, the smallest fix, the reproduction's result after the fix, and remaining uncertainty. Keep incident logs and temporary hypotheses out of durable project memory.
