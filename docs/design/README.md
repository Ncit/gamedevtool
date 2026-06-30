# GameDevTool — Design Reference

The UI is designed in **Pencil** (`/gamedevtool.pen` at the repo root). That file is
**encrypted and only readable through the Pencil MCP server** — a cloud / headless
Claude Code session **cannot open it**. This folder is the bridge: PNG renders, HTML/
Tailwind structure, and CSS tokens that any agent or human can read directly when
implementing the web app.

> When implementing UI, treat these exports as the spec. Match the screenshots; pull
> exact colors/spacing from `tokens.css`; use the HTML files for structure/Tailwind hints.

## Design system

- **Theme:** dark, dense, game-dev tooling aesthetic. Tokens in [`tokens.css`](tokens.css).
- **Fonts:** Inter (UI), JetBrains Mono (ids/code/values).
- **Entity-type color coding** (used everywhere — nodes, dots, icons): mission `#F59E0B`,
  npc `#38BDF8`, dialog `#A78BFA`, plot `#F472B6`, milestone `#34D399`, location/teal
  `#2DD4BF`, item `#FB923C`, faction `#F87171`, quest `#FBBF24`, lore `#94A3B8`.
- **Status colors:** idea (muted), draft (slate), in-progress (amber), done (green), cut (red).
- **Core reusable components** (build these first in React): `Button`, `Input`, `SearchBar`,
  `TagChip`, `StatusPill`, `ConnectionBadge`, `NavItem`, `EntityNode` (graph node, color
  variant per type), `EntityCard`, `InspectorField`, `InspectorPanel`, `Sidebar`, `TopBar`,
  `Modal`, `ActivityItem`, `DialogLineNode`, `DialogChoice`.
- **App shell:** left `Sidebar` (brand + project switcher, entity-type filters with counts,
  settings footer) + `TopBar` (Graph/Table/Tree view switch, search, New Entity) + content.

## Screens (`screens/*.png` — full renders)

| Screen | File | Notes |
|---|---|---|
| Graph Canvas (primary) | `graph-canvas.png` | Dot-grid canvas, typed nodes, curved color-coded directional edges + legend, grouped regions, neighborhood focus + handles, minimap, zoom/fit/lock tools |
| Entity Inspector | `entity-inspector.png` | Docked right panel: status, type-driven fields, typed connections list, actions |
| Entity Table | `entity-table.png` | Name/Type/Status/Tags/Links columns, filters, pagination |
| Dialog Tree Editor | `dialog-tree-editor.png` | dialog_line nodes, branch edges, outcome node, flagged dead-end, consistency warning |
| Mission Dependencies | `mission-dependencies.png` | Layered act columns, requires/unlocks/gates edges, gate locks |
| Plot Timeline | `plot-timeline.png` | Act bands, ordered plot points, milestone checkpoints |
| Milestone Board | `milestone-board.png` | Kanban columns (milestones) with progress + entity cards |
| Consistency Check | `consistency-check.png` | Summary stats + grouped issues (cycles/dead-ends/orphans) with jump-to |
| Agent Activity | `agent-activity.png` | MCP agent feed + git-diff-style change review / revert |
| MCP & Skills | `mcp-and-skills.png` | Server status, `.mcp.json` snippet, skills browser + playbook |
| Create Entity | `create-entity.png` | Type-picker modal over dimmed canvas |
| New Connection | `new-connection.png` | Typed-edge picker popover mid-drag |
| NPC Edit + Validation | `npc-edit-validation.png` | Per-type edit mode with Zod validation error |
| Inspector Variants | `inspector-variants.png` | Milestone / Location / Faction / New-empty panels |
| Command Palette | `command-palette.png` | ⌘K — entities, commands, skills |
| Settings | `settings.png` | AI Models / BYOK, self-host note |
| GDD Import | `gdd-import.png` | Paste GDD → AI-decomposed entity preview |
| Export Dialog | `export-dialog.png` | Yarn / Ren'Py / Godot-Dialogic / articy / ink / Markdown |
| Project Switcher | `project-switcher.png` | Multi-project dropdown |
| Empty Project | `empty-project.png` | First-run state |
| System States | `system-states.png` | Loading / error / disconnected / no-results |
| Node Context Menu | `node-context-menu.png` | Right-click node actions |

## HTML/Tailwind structure (`html/*.html`)

Representative screens exported with structure + Tailwind classes for layout/spacing
reference: `graph-canvas`, `entity-inspector`, `entity-table`, `dialog-tree-editor`,
`agent-activity`. (The dot-grid background is a WebGL shader in Pencil — in the web app,
reproduce it with a CSS radial-gradient tiled background, not the rasterized image.)

## Regenerating these exports

Open `gamedevtool.pen` in Pencil and re-run the export via the Pencil MCP
(`export_nodes` for PNG, `export_html` for HTML, `get_variables` for tokens). The `.pen`
file is the editable source of truth; everything in this folder is generated from it.
