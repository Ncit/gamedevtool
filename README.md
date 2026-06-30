# GameDevTool

An **AI-first, self-hosted game-design tool** for solo devs and small indie teams. It
models a game's design — missions, NPCs, dialogs, plot points, and milestones — as a
**typed, queryable property graph** stored in **SQLite**, and exposes that graph over an
**MCP server** so external AI agents (e.g. Claude Code) can read and write the design
directly. The same graph is edited by humans (web UI) and by AI agents (MCP) — the
"pencil.dev principle": structured data *is* the API.

See **[docs/PLAN.md](docs/PLAN.md)** for the full plan, market analysis, architecture,
data model, MCP/skills design, and milestones.

## Status

Greenfield — planning phase. Implementation has not started yet.

## Pillars

- **Typed graph** of game-design intent with first-class typed edges (`requires`, `unlocks`, `speaks`, `gates`, …).
- **Bring-your-own-agent over open MCP** — no metered AI tax; your own Claude Code drives the design.
- **Self-hosted SQLite** — full data ownership, no cloud lock-in.
- **Plain-text export** — git-diffable history of every AI-made change.
- **Authoring skills** — versioned playbooks served over MCP that teach the agent how to author each feature.
