# Project memory

> Version-controlled source of truth for durable project context. Keep it short, current, and free of secrets.
>
> **Delete every section you cannot fill with a verified fact, including the optional ones below.** An empty placeholder is worse than a missing section: it is read on every session and tells the reader nothing. Sections can be added back the moment there is something real to put in them.

## Purpose

- Primary goal:
- Explicit non-goals:

## Commands

```text
Install:
Run:
Test existing suite:
Lint:
Type-check:
Build:
```

Only list commands actually executed and verified in this repository. Remove the lines that do not apply.

## Architecture

- Main components and their responsibilities:
- Important boundaries:

Keep this to what is not obvious from the directory layout.

## Known constraints and pitfalls

- Durable, verified limitations and recurring traps.
- Not a task list.

---

## Optional sections

Everything below is useful only for some projects. Keep a section when it carries a fact that is not already clear from the code, the tooling, or another canonical file. Otherwise delete it.

### Domain language

| Term | Meaning |
| --- | --- |

Only terms whose meaning is specific to this project.

### Invariants

- Business or data rules that must always hold; link to the implementation.

### Development environment

- Runtime and required versions:
- Package manager:
- External services:

Skip whatever the manifest, lockfile, or version file already states unambiguously.

### Conventions

- Project-specific naming, structure, error handling, API or database conventions.

Do not duplicate what a formatter, linter, or compiler already enforces.

### External integrations

| Integration | Purpose | Contract or documentation | Failure considerations |
| --- | --- | --- | --- |

Never include credentials or real production payloads.

### Active architectural decisions

- [Decision title](decisions/NNN-short-title.md)

Detailed context, alternatives, and consequences belong in the decision record, not here.

### Canonical documentation

- Pointers to documents a newcomer would not find on their own.

---

Update this file in the same change-set that makes it inaccurate. Remove obsolete information instead of keeping an informal changelog; Git already stores the history.
