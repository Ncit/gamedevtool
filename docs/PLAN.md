# Plan: AI-first Game Design Tool ("GameDevTool") — refined with market analysis

## Context

Solo/indie devs design games from a GDD and need to track **missions, NPCs, dialogs,
plot evolution, and milestones** plus the **typed connections between them**. The user
uses Nuclino (graph nodes) but it's a wiki with cosmetic links — it can't model missions,
branching dialog, or cross-entity dependencies.

We're building an **AI-first** replacement on the **pencil.dev principle**: the canonical
source of truth is a structured, machine-readable design graph, and *the same graph* is
edited by **humans (web UI)** and **external AI agents (MCP)**. The UI is a view over the
data the agent manipulates. Target users are **solo devs and small indie teams**; the
**self-hosted single-instance solution ships first**, with multi-user/team collaboration
kept architecturally open for a later phase.

**Locked-in decisions:** self-hosted **web app + SQLite**; MCP exposes the graph so
**external agents (Claude Code) read/write** it; MVP = **core graph + entities**;
deliver **Pencil (.pen) mockups** from a reusable component library. Greenfield repo
(empty dir; blank `gamedevtool.pen`).

---

## Market Analysis & Positioning (from competitive workflow)

The market splits into four camps, **none unifying our four pillars**:

| Camp | Examples | Fatal gap for us |
|---|---|---|
| Narrative/dialog | articy:draft X, Arcweave, Twine, ink, Yarn, Dialogic | Dialog-flow only; no mission/NPC/milestone entities or cross-state; API paywalled/none |
| Worldbuilding/wiki | Obsidian, World Anvil, Kanka, Notion, Nuclino, Logseq/Tana | Edges **untyped & cosmetic**; novelist/GM framing; mostly cloud |
| Game PM/GDD | Codecks, HacknPlan, Milanote, Miro | Track *work* not design entities; taxonomic not a graph; no MCP |
| AI-first / MCP refs | Pencil.dev, Neo4j+Cypher MCP, NovelCrafter, Inworld | Prove each pillar but in another domain/layer |

**Closest threats:** **Notion + official Notion MCP** (relational tables + agent
read/write today, but flat/untyped, cloud, game-agnostic); **articy:draft X** (real
typed object model, but proprietary, Windows, studio-priced, 700-object free cap, no
MCP); **Neo4j + Cypher MCP** (typed graph over MCP, but no game domain or authoring UX).

**Market-wide weaknesses we fix:** (1) untyped/cosmetic edges — you can't query
"what depends on this mission"; (2) no cross-NPC/cross-mission state; (3) cloud lock-in;
(4) **metered/recurring AI cost** (indies' loudest complaint); (5) paywalled or absent
API/MCP; (6) AI as bolt-on generator, not an agent traversing the whole design.

**Our differentiation (lead the positioning with this):**
- Typed, **traversable** game-design graph (edges like `requires/unlocks/speaks/gates`) — vs cosmetic links and fixed narrative-flow schemas.
- **Bring-your-own-agent over open MCP**: the dev drives design with the Claude Code they already pay for — no metered AI tax, no locked-in first-party assistant.
- **Self-hosted local SQLite** as the single source of truth — full data ownership, no per-action cost, no 700-object cap.
- **Open, inspectable store + plain-text export** → git-diffable history of every AI-made change (beats Pencil's opaque file and raw-SQLite's binary-diff problem).
- **Game-design-native schema out of the box** (quest state, gating, branching) — vs DIY Notion/Obsidian templates.
- **Self-hosted, no object caps, no per-action AI tax** for solo devs *and* indie teams (vs articy's 700-object cap + studio licensing, Arcweave/World Anvil paywalled APIs, Inworld/Ludo metered cost). Team collaboration comes in a later phase.

**Scope sequencing (updated):** target is **not solo-only** — indie *teams* are in
scope too. We ship the **self-hosted single-instance solution first**, and the
architecture must **not preclude multi-user/team collaboration later** (a self-hosted
instance can serve several users; we just don't build real-time collab in the first
release). Real-time multiplayer editing is a later phase, deliberately deferred — not
designed out.

**Moat caveat:** "graph-over-MCP" is commoditizing (Neo4j/Notion). Our moat is the
**opinionated game-design domain model + turnkey SQLite/MCP packaging + authoring UX**,
not the idea itself — so the domain schema and onboarding must be visibly excellent.

---

## Architecture & Stack

Monorepo (pnpm workspaces) so the web app and MCP server **share one data layer**:

```
gamedevtool/
  packages/
    db/        # Drizzle ORM schema + migrations + Zod type schemas + query helpers (shared core)
    mcp/       # MCP server (stdio + optional Streamable HTTP) -> imports packages/db
    export/    # SQLite <-> plain-text (JSON/Markdown) sync for git-diffable history + engine exporters
    skills/    # versioned markdown authoring playbooks served to the LLM via MCP (get_skill)
  apps/
    web/       # Next.js 15 (App Router) + React 19 + TS UI + API
  data/project.db        # SQLite (gitignored); design/ holds the text mirror (committed)
  docker-compose.yml
  gamedevtool.pen
```

- **DB:** SQLite via **Drizzle + better-sqlite3**. Recursive-CTE traversal + an adjacency index so dependency queries stay fast (raw SQLite isn't a graph DB — treat traversal perf as a core feature, not an afterthought).
- **Web:** **Next.js 15 + React 19 + TS**, Server Actions for mutations.
- **Graph canvas:** **React Flow (`@xyflow/react`)** — custom node types per entity type, custom typed edges, minimap.
- **Sync after external edits:** TanStack Query polling so UI reflects agent edits.
- **MCP:** `@modelcontextprotocol/sdk`. Primary **stdio** (no-auth local, user adds to `.mcp.json`); optional **Streamable HTTP behind OAuth 2.1/PKCE** for any future remote use. Imports `packages/db` directly.
- **Packaging:** `docker-compose up` self-host; `pnpm dev` local.

Why: `packages/db` is the single source of truth; web app and MCP server are thin clients
over it, so a human edit and an agent edit are identical writes — pencil.dev principle in
the architecture itself.

---

## Data Model (typed nodes + first-class typed edges)

A **property graph** — everything is a typed node, every relationship a **typed, queryable** edge.

**`projects`** — `id, name, description, timestamps`

**`entities`** (nodes) — `id, project_id, type, title, summary, body(md), status, properties(JSON), pos_x, pos_y, tags(JSON), timestamps`
- default `type` ∈ `mission | quest | npc | dialog | dialog_line | plot_point | milestone | location | item | faction | lore`
- **user-extensible** node types (where articy is rigid).

**`connections`** (edges — first-class, the thing wikis lack) — `id, project_id, source_id, target_id, type, label, properties(JSON), timestamps`
- default `type` ∈ `requires | unlocks | leads_to | precedes | speaks | located_at | rewards | references | branches_to | gates | member_of`
- user-extensible.

**Dialog uses the same tables** (not a special case): a `dialog` owns `dialog_line`
entities; player choices are `branches_to` edges with a `condition` in `properties`. One
graph engine renders missions *and* dialog trees.

Type-specific shape lives in `properties`, validated by **Zod schemas keyed by `type`**
(in `packages/db`) — mission → `{objective, reward, prerequisites}`, npc → `{role, faction, location}`,
milestone → `{due, order}`. **Both UI forms and MCP tools validate against the same Zod
schemas** (single definition, two consumers). **Milestones link to design nodes**
(HacknPlan Game Design Model pattern) via `precedes`/`requires` edges, closing the
design→production gap.

Indexes: `(project_id, type)`, `connections(source_id)`, `connections(target_id)`, plus a precomputed adjacency/closure helper for deep dependency queries.

---

## MCP Server (Pencil-style, external agents read/write)

Design lessons taken from Pencil.dev / Neo4j MCP servers:

- **Tools** (mutations): `create_entity`, `update_entity`, `delete_entity`, `create_connection`, `delete_connection`, plus **batch variants** (`batch_apply`) so large-graph agent edits aren't chatty round-trips.
- **Read tools / Resources**: `get_design_state(include_schema)` (runtime schema discovery so the agent self-orients — mirrors Pencil's `get_editor_state`), `search_entities`, `get_entity` (+neighbors), `get_graph` (full or N-hop subgraph), and a readable resource `project://{id}/graph` for cheap whole-design context.
- **Prompts / analysis tools** (the Arcweave features, but free & agent-run over the typed graph): `check_consistency`, `find_unreachable_missions`, `find_dialog_dead_ends`, `check_gating_consistency`, `find_dependency_cycles`, `summarize_quest_line`, `find_orphans`.

- **Skill/guide discovery** (mirrors Pencil's `get_guidelines`): `list_skills` and `get_skill(name)` so the agent loads the right authoring playbook on demand before touching a feature (see next section).

This is the AI-first core: an agent reads the whole design, reasons over typed
relationships, and edits through the same typed ops a human uses — at **zero per-run cost**
because it's the user's own Claude Code, not a metered service.

---

## Authoring Skills / Guides (LLM playbooks per feature)

A core part of the product (not an afterthought): the MCP server **serves versioned
guides that teach the LLM how to author each feature correctly** — exactly how Pencil's
`get_guidelines` teaches an agent to build UI. Without these, an external agent improvises
node/edge shapes inconsistently. With them, the tool ships **opinionated game-design
methodology** the agent follows — a real differentiator.

**Delivery:** markdown guides in `packages/skills/`, exposed over MCP via `list_skills`
(returns names + one-line "when to use") and `get_skill(name)` (returns the full
playbook + the exact entity/edge types and Zod-validated fields to use). Each guide is
**concrete and actionable**: what nodes to create, which typed edges to wire, which
`properties` to fill, the common patterns, and the validation/consistency check to run
afterward. The same guides can also be packaged as bundled Claude Code skills for users
who prefer that surface.

**MVP guide set (one per core feature):**
- `dialog-authoring` — build a branching dialog: a `dialog` node owning `dialog_line` nodes, `branches_to` edges carrying `condition`, speaker wired via a `speaks` edge from the NPC; avoid dead ends; run `find_dialog_dead_ends` after.
- `mission-design` — `mission` node with `objective/reward/prerequisites`; prerequisites as `requires` edges; unlocks as `unlocks` edges; gating via `gates`; verify with `find_unreachable_missions` + `find_dependency_cycles`.
- `plot-structure` — `plot_point` nodes ordered via `precedes`/`leads_to`, tied to `milestone` nodes so narrative maps to production.
- `npc-design` — `npc` with `role/faction/location`; wire `member_of` (faction), `located_at` (location), and dialog ownership via `speaks`.
- `milestone-planning` — `milestone` nodes with `order/due`, linked to the design nodes they ship (HacknPlan GDM pattern).
- `worldbuilding` — `location`/`item`/`lore`/`faction` nodes and how to cross-reference them with `references`/`located_at`.
- `consistency-review` — when/how to run the analysis tools and how to fix what they flag.

**Later guides:** `gdd-import` (decompose a pasted GDD into the graph), `dialog-localization-export`, `quest-balancing`.

---

## Plain-text Export / Git layer (load-bearing differentiator)

`packages/export` keeps a **plain-text mirror** (JSON + Markdown, one file per entity)
in `design/`, synced from SQLite. This makes **every AI-made change git-diffable and
reviewable** — the trust mechanism that beats opaque stores. Same layer hosts
**engine exporters** (ink-style clean JSON, plus Yarn / Ren'Py / Godot-Dialogic and
articy-compatible JSON), positioning us as the engine-neutral **system-of-record** that
feeds existing pipelines rather than replacing engines.

---

## UI & Pencil Mockups (reusable components)

`.pen` is empty → **build a component library first, then instance it** (Pencil "Design
System" workflow). Dark, dense, game-dev tooling aesthetic.

1. **Tokens/theme** — color/type/space variables (dark) as `.pen` variables.
2. **Reusable components** (build once, instance everywhere): `Button`, `Input`,
   `SearchBar`, `TagChip`, `StatusPill`, `NavItem`, `Toolbar`, `Tabs`, `Breadcrumb`,
   `EmptyState`, `EntityCard`, `EntityNode` (variants per type/color), `ConnectionBadge`,
   `InspectorField`, `InspectorPanel`, `DialogLineNode`, `AppShell` (sidebar+topbar+content+inspector).
3. **Screens** (composed from the above): **(MVP)** Graph canvas, Entity inspector,
   Entity table view; **(later)** Dialog tree editor, MCP/agent activity panel
   (shows external-agent edits → trust + transparency), Milestone view.

Multiple synchronized views (graph + tree + document) of the same store serve both visual
and list-oriented designers (HacknPlan pattern, taken further on true graph expressiveness).

---

## MVP Scope & Milestones

**M1 — Foundation (core, per user):** monorepo, `packages/db` schema + migrations + Zod
type schemas + seed. **Accept:** create a project, entities of every core type, **typed**
connections; dependency query ("what requires X") returns correct results.

**M2 — Web app core:** app shell, React Flow graph canvas (render/move/connect, persist
positions), type-driven entity inspector, entity table view. **Accept:** author a small
game design entirely in the UI.

**M3 — MCP server + authoring skills:** stdio server over `packages/db` with batch CRUD,
`get_design_state`, `get_graph`, `search_entities`, the consistency analyses, and
`list_skills`/`get_skill`; write the MVP guide set in `packages/skills/`. **Accept:**
Claude Code (via `.mcp.json`) loads `get_skill('mission-design')`, authors a mission +
NPC + dialog following it, and the result passes the consistency tools; UI reflects the
agent edits on refetch.

**M4 — Pencil mockups:** component library + the 3 MVP screens in `gamedevtool.pen`, used
to drive/refine the M2 UI.

**M5 — Trust & export:** plain-text mirror to `design/` (git-diffable) + one engine
exporter. **Accept:** an agent edit produces a clean, reviewable git diff.

**Later (out of MVP):** GDD-to-graph AI import, dialog tree editor, milestone timeline,
auto-linking of entity mentions (NovelCrafter codex), task-pipeline spawning (Codecks
Journeys), starter templates/importers for fast onboarding, BYOK/local-model option.

---

## Critical files to create

- `packages/db/schema.ts` — Drizzle tables (`projects`, `entities`, `connections`)
- `packages/db/types.ts` — Zod schemas per entity/connection `type`
- `packages/db/queries.ts` — shared query/mutation + traversal (recursive CTE) helpers
- `packages/db/migrations/*`
- `packages/mcp/server.ts` — Tools / Resources / Prompts + `list_skills`/`get_skill` registration
- `packages/skills/*.md` — authoring playbooks (dialog, mission, plot, npc, milestone, worldbuilding, consistency)
- `packages/export/` — text mirror + engine exporters
- `apps/web/app/` — graph canvas, inspector, table view; `apps/web/components/graph/` custom nodes/edges
- `docker-compose.yml`, `pnpm-workspace.yaml`
- `gamedevtool.pen` — component library + screens (Pencil tools only)

## Verification (end-to-end)

1. **Model/traversal:** migrate + seed; vitest asserts CRUD, Zod rejection of bad `properties`, and a recursive dependency query ("what requires mission X").
2. **MCP parity:** start stdio server, point Claude Code via `.mcp.json`; from Claude Code create NPC + mission + `speaks`/`requires` edges, `get_graph`, run `check_consistency`; confirm SQLite rows.
3. **UI ↔ MCP:** open web app, see agent-created nodes on canvas; edit a node in UI; re-query over MCP and confirm — one shared graph.
4. **Consistency:** intentionally create an orphan NPC + a mission dependency cycle + a dialog dead-end; confirm the analysis tools flag all three.
5. **Authoring skills:** from Claude Code call `list_skills` then `get_skill('dialog-authoring')`; have the agent build a branching dialog by following only the guide; confirm the produced nodes/edges match the documented shape and pass `find_dialog_dead_ends`.
6. **Git-diff trust:** make an agent edit; confirm `design/` text mirror updates into a clean, human-readable git diff.
7. **Pencil:** screenshot the 3 MVP screens; confirm they're built from instanced components (no one-off duplicates).
