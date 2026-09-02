# AI ecosystem notes

Status: documentation notes only.
Source: `/home/wilian/Downloads/chatgpt_Explicar_terras_raras.pdf`, exported on 2026-08-19 08:33:14.

## Core idea

Build a modular AI-agent ecosystem with separate containers per capability and controlled filesystem access.

## Suggested architecture

- Keep the agent container isolated.
- Run MCP File System in a separate container.
- Mount only the folders the agent may access, for example:
  - `Downloads`
  - `Projects`
  - `AgentData`
- Do not expose the whole machine to the agent.
- Use organized input and output folders, such as:
  - `AgentInbox`
  - `AgentOutbox`
- Centralize artifacts and data in one shared folder used only by authorized services.

## Compose services

Possible Docker Compose services for the ecosystem:

- File System
- GitHub
- Playwright
- Memory
- Context7
- Database

Goal: preserve portability across Claude Code, Codex, and other future agents.

## Database options

- SQLite
  - Good for local memory, lightweight configuration, simple backups, and easy synchronization.
- Postgres
  - Best fit for a more robust base.
  - Recommended when multiple agents need to access shared data.
  - Scales well and has strong extensions.
- Redis / Valkey
  - Better as cache or ephemeral memory, not as the main database.
  - Valkey is an open Redis-compatible alternative.
- DuckDB
  - Useful for heavier data analysis.
  - Not necessary at the beginning.
- Vector database
  - Avoid at the start.
  - Add only when there is a concrete retrieval need.

## Recommended initial base

- Postgres as stable memory and main database.
- Valkey as fast cache / ephemeral memory layer.
- Structured filesystem for artifacts, documents, inputs, and outputs.

## Evolution principle

Start simple, modular, and safe.

Add services only when a concrete need appears. Avoid premature complexity and keep the infrastructure easy to evolve without rewriting everything.

## Operational sketch

```text
AI Agent container
  -> MCP File System container
       -> mounted folders only: AgentData / AgentInbox / AgentOutbox / Downloads / Projects as needed
  -> MCP GitHub
  -> MCP Playwright
  -> MCP Memory
  -> MCP Context7
  -> Postgres
  -> Valkey
```

Main security rule:

```text
The agent can only access what is explicitly mounted as a volume.
```
