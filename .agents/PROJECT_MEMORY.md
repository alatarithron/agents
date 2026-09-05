# Project memory

## Project purpose

- Primary goal: one canonical file of personal working rules, wired into every AI tool, plus the templates and checks that carry the same rules into other repositories.
- Explicit non-goals: not a framework, not a product, not project memory for any single repository.
- Intended users: the owner. Public for transparency.

## Architecture

- `AGENTS.md` — the canonical personal rules. Symlinked into the global tool files; see [001](decisions/001-root-agents-is-the-canonical-file.md).
- `wire.sh` — creates those global symlinks. `adopt.sh` — installs the structure into a project. Both idempotent.
- `check.sh` — reports structure and policy heuristics; `test-check.sh` exercises positive and negative cases.
- `template-diff.sh` — read-only template comparisons; `test-scripts.sh` exercises adoption and global wiring inside isolated fixtures.
- `templates/` — copied into adopted projects. `reference/` — long-form material, never loaded automatically by agents.

## Domain language

| Term | Meaning |
| --- | --- |
| canonical file | The root `AGENTS.md`, source of truth for personal rules. |
| adopted project | A repository carrying `AGENTS.md` + `.agents/`, installed by `adopt.sh`. |
| entry form | The per-item size limit on memory entries; measured by `check.sh`. |
| baseline | A falsifiable expectation with a date, as opposed to a run result. |

## Invariants

- The root `AGENTS.md` is read in every session of every tool: a line that does not change a decision is pure cost.
- `wire.sh` never overwrites a regular file, and `adopt.sh` never overwrites anything.
- `check.sh` and `template-diff.sh` only report. `adopt.sh` writes only into its explicit target; `wire.sh` changes global configuration only when explicitly invoked.

## Development environment

- Linux, Bash and GNU utilities. Git is optional for adoption and comparison, required for the development test suite; ShellCheck is the lint tool. No package-manager project or application runtime.

## Commands

```text
Install:             none
Run (global wiring): ./wire.sh
Run (adopt project): ./adopt.sh <project-dir>
Test existing suite: ./test-check.sh && ./test-scripts.sh
Lint:                shellcheck ./*.sh
Verify a project:    ./check.sh <project-dir>
```


## Conventions

- Portuguese in `README.md` and `reference/`; English in `AGENTS.md` and `templates/`, which live inside code repositories.
- Scripts are dependency-free Bash, idempotent, and must stay `shellcheck`-clean.

## External integrations

| Integration | Purpose | Contract or documentation | Failure considerations |
| --- | --- | --- | --- |
| Global tool files | Deliver the canonical rules to each tool | `wire.sh` | A tool that reads a regular file instead of a symlink is skipped, never overwritten. |

## Active architectural decisions

- [The root AGENTS.md is the canonical file, not a project file](decisions/001-root-agents-is-the-canonical-file.md)
- [Project-local skills and template provenance](decisions/002-project-local-skills-and-template-provenance.md)

## Known constraints and pitfalls

- Editing `AGENTS.md` changes behaviour in every tool on this machine at once, with no staging step.
- `templates/AGENTS.project.md` deliberately restates rules from `AGENTS.md`; the mirrored sections are mapped in `templates/README.md` and drift silently if only one side is edited.
- Adopted files are independent copies. `template-diff.sh` compares them without overwriting local rules; provenance is inert text, not an executable configuration.
- `.agents/skills/` holds on-demand procedures. Native discovery differs by tool; the template instructs agents to read matching files explicitly.
- `templates/BOOTSTRAP.md` is first-session guidance, not routine context. Rules live in project `AGENTS.md`; commands and architecture live in memory only.
- `check.sh` thresholds (400/1200) are calibrated on two adopted projects, not derived. Treat a failure as a question, not a verdict.

## Canonical documentation

- `README.md` (how the repository is used), `reference/PROJECT-MEMORY-POLICY.md` (the full memory policy).

## Maintenance

Update this file in the same change-set that makes it inaccurate. Git already stores the history.
