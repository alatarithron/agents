# Architectural decision: the root AGENTS.md is the canonical file, not a project file

- Status: accepted
- Date: 2026-08-31
- Supersedes: none
- Superseded by: none

## Context

Every adopted project carries an `AGENTS.md` at its root holding rules for agents working *in that repository*. This repository has an `AGENTS.md` at its root too, but it is a different thing: the canonical personal rules, symlinked into `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` and the other global tool files.

So adopting the pattern here collides with itself. The slot the pattern reserves for project instructions is already occupied by a file with a wider audience, and `check.sh` — which assumes an adopted project — reported this repository as broken.

Adding project rules to the root file would push them into every session of every tool, for every unrelated project. That is the opposite of what the file is for.

## Decision

The root `AGENTS.md` keeps its single role: canonical personal rules, and nothing specific to this repository.

This repository adopts the rest of the pattern — `.agents/PROJECT_MEMORY.md` and `.agents/decisions/` — and its own working rules live in the memory, under Invariants and Known constraints, where an agent reads them before changing code.

`check.sh` requires an `AGENTS.md` and a `PROJECT_MEMORY.md`. Both exist here, so the check passes without a special case.

## Alternatives considered

### Rename the canonical file and create a project `AGENTS.md`

- Advantages: the pattern would hold with no exception.
- Disadvantages: breaks every global symlink and the canonical path documented in the file itself and in the README.
- Reason not chosen: the cost lands on every tool on the machine to fix a naming collision in one repository.

### Add a "Repository-specific rules" section to the canonical file

- Advantages: no new file; mirrors what adopted projects do.
- Disadvantages: those rules would be loaded in every session of every project, forever.
- Reason not chosen: the canonical file is the most expensive context in the setup; filling it with rules about itself is the exact waste it warns against.

### Exempt this repository from `check.sh`

- Advantages: no work.
- Disadvantages: the tool that verifies the pattern would carry a special case for the repository that defines it.
- Reason not chosen: an exemption hides the question instead of answering it.

## Consequences

### Positive

- The canonical file stays about personal rules, and the global symlinks keep working untouched.
- `check.sh` runs here with no exception, so the repository is verified by its own tool.

### Negative or trade-offs

- An agent that reads only the root `AGENTS.md` here learns the personal rules but nothing about this repository; it has to reach `.agents/PROJECT_MEMORY.md`, which the canonical file's own Project memory section instructs it to do.
- The repository is a partial adoption, and that asymmetry has to be explained — this record is the explanation.

## Verification

`./check.sh .` from the repository root passes. The root `AGENTS.md` contains no section naming this repository, and `wire.sh` still resolves the global symlinks to it.

## References

- `README.md`, `reference/PROJECT-MEMORY-POLICY.md`, `templates/README.md`
