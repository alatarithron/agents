# Project skills

Versioned procedures, loaded on demand. Rules remain in `AGENTS.md`; verified facts remain in `.agents/PROJECT_MEMORY.md`.

| Skill | Trigger |
| --- | --- |
| [code-simplifier](code-simplifier/SKILL.md) | Explicit cleanup request or one bounded pass over task changes before final validation. |
| [debugging](debugging/SKILL.md) | Unexpected behavior, a failing check, or a regression. |
| [pre-commit-review](pre-commit-review/SKILL.md) | Review request or an authorized commit. |

Read only the matching skill. Never bulk-load all skill bodies. A skill does not override repository rules, approval requirements, or the user's current request.

These files use the `SKILL.md` format with `name` and `description`. Native discovery depends on the tool: if unavailable, open the relative path directly as instructed by `AGENTS.md`. This kit does not modify global skill stores or claim automatic discovery in every agent.

To add a skill, create `<name>/SKILL.md` with YAML frontmatter, a narrow trigger, actionable procedure, pitfalls, and verification. Review executable helpers and permissions before use. Keep external sources pinned and licensed; never auto-fetch or execute a skill during project adoption.
