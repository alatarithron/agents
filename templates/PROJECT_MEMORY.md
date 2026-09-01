# Project memory

> Version-controlled source of truth for durable project context. Keep it current and free of secrets.
>
> **Delete every section you cannot fill with a verified fact.** An empty placeholder is worse than a missing section: it is read on every session and tells the reader nothing. Add a section back the moment there is something real to put in it. Every section below has earned its place in a real project — none is decorative.

## Project purpose

- Primary goal:
- Explicit non-goals:
- Intended users:

## Architecture

- Main components and their responsibilities:
- Important boundaries:
- Data flow:

Keep this to what is not obvious from the directory layout.

## Domain language

| Term | Meaning |
| --- | --- |

Only terms whose meaning is specific to this project.

## Invariants

- Business or data rules that must always hold; link to the implementation or canonical documentation.

## Development environment

- Supported operating systems:
- Runtime and required versions:
- Package manager:
- External services:

Skip whatever the manifest, lockfile, or version file already states unambiguously.

## Commands

```text
Install:
Run:
Test existing suite:
Lint:
Type-check:
Build:
```

Only list commands actually executed and verified in this repository. Remove the lines that do not apply, and say which check is knowingly not clean today.

## Conventions

- Project-specific naming or structure:
- Error-handling conventions:
- API or database conventions:
- Compatibility requirements:

Do not duplicate what a formatter, linter, or compiler already enforces.

## External integrations

| Integration | Purpose | Contract or documentation | Failure considerations |
| --- | --- | --- | --- |

Never include credentials or real production payloads.

## Active architectural decisions

- [Decision title](decisions/NNN-short-title.md)

Detailed context, alternatives, and consequences belong in the decision record, not here.

## Known constraints and pitfalls

- Durable, verified limitations and recurring traps.
- Not a task list.

## Canonical documentation

- Pointers to documents a newcomer would not find on their own.

## Maintenance

Update this file in the same change-set that makes it inaccurate. Remove obsolete information instead of keeping an informal changelog; Git already stores the history.
