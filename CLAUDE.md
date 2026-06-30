# GameDevTool

AI-first, self-hosted game-design tool for solo devs and small indie teams. The design —
missions, NPCs, dialogs, plot points, milestones — is a **typed property graph** in
**SQLite**, exposed over an **MCP server** so external AI agents (Claude Code) read/write
the same graph a human edits in the web UI. ("pencil.dev principle": structured data IS the API.)

**Full plan:** [`docs/PLAN.md`](docs/PLAN.md) — architecture, data model, MCP + authoring
skills, milestones, and verification. Read it before implementing.

## Building the UI — read this first

The entire UI is already designed and lives in [`docs/design/`](docs/design/). **This is
the authoritative UI spec.**

- ⚠️ **Do NOT try to open `gamedevtool.pen`.** It is encrypted and only readable through the
  Pencil MCP, which is unavailable here. It is the editable design source, not a build input.
- ✅ **Build the web UI from `docs/design/` instead.** Start at
  [`docs/design/README.md`](docs/design/README.md). For each screen use:
  - `docs/design/screens/<name>.png` — the visual truth (match this)
  - `docs/design/html/<name>.html` — exact Tailwind structure / spacing / measurements
  - `docs/design/tokens.css` — exact colors, fonts, radii (port into the Tailwind theme)
- **22 screens** and **17 reusable components** are specified. Build the components first,
  then compose the screens.
- Reproduce, don't copy: the graph's dot-grid background is a shader → use a tiled CSS
  radial-gradient; graph edges are SVG beziers → use React Flow edges. Exports are static
  single-state snapshots (alternate states are their own screens).

## Stack (see PLAN for detail)

pnpm monorepo: `packages/db` (Drizzle + better-sqlite3 + Zod, the shared core),
`packages/mcp` (MCP server, stdio), `packages/skills` (authoring playbooks),
`packages/export` (plain-text mirror + engine exporters), `apps/web` (Next.js 15 + React 19
+ React Flow). Build order: M1 db → M2 web UI (from `docs/design/`) → M3 MCP + skills →
M5 export.
