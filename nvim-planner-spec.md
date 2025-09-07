
# nvim‑planner.lua — Comprehensive Requirements & Build Plan

> **Purpose**: This document is written for an AI coding agent (e.g., **Codex CLI**) to implement a Neovim plugin that unifies a **planner, todo manager, notes app, and calendar** into a cohesive, modern, keyboard‑centric workflow. It includes detailed requirements, data contracts, UX rules, file layout, APIs, implementation plan, and test cases.

---

## 1) Product Overview

- **Plugin name (working)**: `smartplanner.nvim` (alias: `nvim-planner.lua`).
- **Target user**: A senior full‑stack engineer who uses Neovim for **coding**, **daily task planning**, **weekly/monthly todos**, **notes**, and **sprint/release scheduling**.
- **Primary goals**:
  1. Keep all planning artifacts close to code, in Neovim.
  2. Offer fast capture, powerful search, and frictionless navigation.
  3. Provide a **calendar UI** with support for **multi‑day spans** (e.g., sprints) displayed above single‑day items.
  4. Support **year‑scoped planners** with **lazy loading** of data to maintain speed.
  5. Offer **popup modals/menus**, **telescope pickers**, and **sensible keymaps**.
  6. Provide a **mini‑mode calendar** that highlights the **current day in view** in the planner (acts as a live mini‑map to indicate scroll position).

- **Non‑goals**:
  - Not a full project management suite; it focuses on personal org and dev cadence.
  - No cloud sync is implemented by default (but filesystem‑based storage allows external sync tools).

---

## 2) Scope & Feature Set

### 2.1 Core Objects / Entities

All entities share: `id` (uuid), `title`, `created_at`, `updated_at`, `tags[]`, `priority`, `order_index`, `calendar` (e.g., `Work`, `Personal`).

1. **Task**
   - Fields: `due_date?`, `start_date?`, `end_date?` (optional multi‑day); `status {todo|doing|done|blocked|canceled}`, `estimate? (minutes)`, `actual? (minutes)`, `parent_id?` (for subtasks), `notes? (string)`.
   - Behavior: tasks can live on a specific day or be scheduled across multiple days; can be promoted to an **Event** for calendar emphasis.

2. **Event**
   - Fields: `start_datetime`, `end_datetime`, `allday (bool)`, `span (bool)`; `location?`, `external_ref?`.
   - Behavior: events are **pinned in calendar** and can span multiple days; **displayed above** same‑day items.

3. **Note**
   - Fields: `date?` (anchor date), `body (markdown)`, `links[]` (backlinks/refs).
   - Behavior: freeform markdown with optional front‑matter; appears in day/weekly context.

4. **Sprint** (multi‑day band)
   - Fields: `name`, `start_date`, `end_date`, `objective?`, `milestones[]`, `color?`.
   - Behavior: renders as a **horizontal band across days/weeks** at the **top band region** in calendar views.

### 2.2 Views

- **Planner View** (main buffer):
  - Day/Week/Month **sections** with nested items (Tasks, Events, Notes).
  - Collapsible groups; keyboard‑first editing; inline add/convert; drag/move by keys.

- **Calendar View**:
  - **Month** grid + **Week** row view + **Day** column view.
  - **Multi‑day spans** (Sprints/Events) rendered in a **top band** for each day cell.
  - **Order**: (1) Spans/Sprints/All‑day Events (top) → (2) Dated Tasks/Notes (below).
  - **Mini‑Mode** (floating or right/left sidebar): shows current month; **highlights the planner’s current visible day** (acts as a viewport indicator/mini‑map).

- **Capture Modal**:
  - Quick add ("`t`" task, "`e`" event, "`n`" note, "`s`" sprint) with natural dates ("Mon 9am", "next Fri"), tags, priority.

- **Find/Jump (Telescope)**:
  - Pickers: `Tasks by status/priority/tag`, `Events by date range`, `Notes by tag`, `Sprints by date`, `Today/This week`, `Go to date`.

### 2.3 Year‑Scoped Data & Lazy Loading

- A new **planner is created per year**.
- Data is partitioned by **year root folders**.
- **Lazy load**: Only load data for the **active month(s)** in view; prefetch ±1 month on scroll.

### 2.4 Ordering Rules in Calendar

- For any given day cell:
  1. **Top band**: Spanning items first (Sprints, multi‑day Events with `span==true`, all‑day events).
     - Sort by: `priority DESC`, then `order_index ASC`, then `start_date`.
  2. **Below**: Single‑day items (Events without span, Tasks anchored to that date, Notes anchored to that date).
     - Sort by: `time ASC` (for timed events), then `priority DESC`, then `order_index ASC`, then `title`.

- When a spanning item intersects the visible range, render it across the intersecting cells with **continuation chevrons** (◀ ▶) for overflow boundaries.

### 2.5 Mini‑Mode Calendar Highlight (Viewport Sync)

- Track planner’s **current visible date range** via window scroll.
- Compute active **focus_day** (topmost visible day header or cursor‑anchored day).
- In Mini‑Mode, **highlight `focus_day`**; also show a subtle band for the visible range if the planner view spans multiple days.
- Update on `CursorMoved`, `WinScrolled`, or explicit `:SmartPlannerSync`.

### 2.6 Key Capabilities

- **Keyboard‑first editing**: create, edit, move, convert types, change status, reschedule, bump priority, reorder (`order_index`).
- **Popup modals** using `nui.nvim`/`vim.ui.select` for consistent style.
- **Status line/Winbar** integration (optional) to show current focus and sprint.
- **Render Markdown** integration for notes (works with `render-markdown.nvim`).
- **Telescope** sources for search/jump.
- **Export** day/week/month to Markdown/CSV.

---

## 3) Storage & File Layout

> Default to **filesystem** with front‑matter YAML + Markdown bodies; optional **SQLite** backend for power users. Storage paths must be configurable.

### 3.1 Default Paths (Windows‑friendly and *nix)

```
~/.local/share/smartplanner/
  ├─ 2025/
  │   ├─ calendars.json                 # registry of calendars (Work, Personal)
  │   ├─ sprints.json                   # list of sprint bands
  │   ├─ months/
  │   │   ├─ 2025-01.json               # month shard (tasks/events/notes indexes)
  │   │   ├─ 2025-02.json
  │   │   └─ ...
  │   └─ notes/
  │       ├─ 2025-01-07-leads-sync.md  # markdown with YAML front‑matter
  │       └─ ...
  └─ assets/                            # attachments if needed
```

- **Sharded month JSON** holds normalized lists for fast load:
  - `tasks[]`, `events[]`, `notes_index[]` (each item references a `.md` when applicable).
  - All items include `calendar` and `order_index`.

- **Front‑matter schema** (example for a note file):

```yaml
---
id: 9e5e5a18-4c2c-4a8a-9d15-97bf7a3c9a11
calendar: Work
date: 2025-09-12
tags: [meeting, bolt]
links: []
---
```

- **SQLite mode** (optional): `~/.local/share/smartplanner/smartplanner.db`
  - Tables: `tasks`, `events`, `notes`, `sprints`, `tags`, `links`.
  - Provide a minimal DAO abstraction; filesystem remains the default.

### 3.2 Import/Export

- `:SmartPlannerExport {range} --fmt=md|csv --scope=day|week|month`.
- `:SmartPlannerImport --from=<path>` for bulk migration.

---

## 4) Configuration API (Lua)

```lua
require("smartplanner").setup({
  default_calendar = "Work",
  calendars = {
    Work = { root = vim.fn.stdpath("data") .. "/smartplanner/Work" },
    Personal = { root = vim.fn.stdpath("data") .. "/smartplanner/Personal" },
  },
  year_root = vim.fn.stdpath("data") .. "/smartplanner/%Y", -- strftime pattern
  float_style = { border = "rounded", width = 92, height = 24, winblend = 0, zindex = 50 },
  storage = { backend = "fs", preload_months = 1 }, -- backend: fs|sqlite
  timezone = "Australia/Melbourne",
  telescope = { enable = true },
  markdown = { render = true },
  keymaps = "default"
})
```

- **Notes**:
  - `year_root` supports `%Y` expansion.
  - `preload_months` controls lazy prefetch.
  - `timezone` only affects display/formatting; times are stored in ISO‑8601 (UTC) with tz offset saved.

---

## 5) Commands & Keymaps

### 5.1 User Commands

- `:SmartPlannerOpen [view=planner|calendar|mini] [date=YYYY-MM-DD]`
- `:SmartPlannerCapture [type=task|event|note|sprint] [date=...]`
- `:SmartPlannerGoto [today|week|month|YYYY-MM-DD]`
- `:SmartPlannerSearch [tasks|events|notes|sprints] [query=...]`
- `:SmartPlannerExport ...`
- `:SmartPlannerConfig` (open current config help)
- `:SmartPlannerSync` (force mini‑mode highlight sync)

### 5.2 Suggested Default Keymaps (Normal mode)

- `\sp` → Open Planner (today)
- `\sc` → Open Calendar Month (current)
- `\sm` → Toggle Mini‑Mode calendar sidebar
- `\sT` → Capture Task (modal)
- `\sE` → Capture Event (modal)
- `\sN` → Capture Note (modal)
- `\sS` → Capture Sprint (modal)
- `\sg` → Go to date (picker)
- `]d` / `[d` → Next/prev day section
- `]w` / `[w` → Next/prev week section
- `\su` / `\sd` → Move item `order_index` up/down
- `\sr` → Reschedule (date picker)
- `\sx` → Toggle Task status (todo → doing → done → todo)

(*Customize under `setup.keymaps`.)

---

## 6) UI & Rendering Rules

### 6.1 Planner Buffer Structure

- Markdown‑like headings:
  - `# 2025-09-07 (Sun)` (day headers, foldable)
  - Under a day: sections **Tasks**, **Events**, **Notes** (foldable).
- Inline icons/glyphs for status (`[ ]`, `[~]`, `[x]`), priority (`!…`), tags (`#tag`).
- Context actions via `K` (hover) or `\s?` for help.

### 6.2 Calendar Month Grid

- Each cell contains:
  1. **Top band**: Spans (Sprints, all‑day/multi‑day events). Wrap across days; show chevrons when clipped.
  2. **Items list**: Timed events/tasks/notes (line‑clamped with `+N more`).
- Today’s date ring; **focus_day highlight** when Mini‑Mode indicates current planner viewport.

### 6.3 Mini‑Mode Calendar

- Narrow (20–24 cols), always‑on or toggleable.
- Shows month name/navigation (`h/j/k/l` to move month/week/day).
- **Highlight**: `focus_day` (derived from planner viewport). Optionally shade the whole visible range.

### 6.4 Modals

- Unified modal component for capture/edit; uses input prompts with validation and fuzzy tag/date selection.

---

## 7) Data Flows & Algorithms

### 7.1 Lazy Loading

1. On open, compute year folder for `focus_day`.
2. Load shard for `focus_month` + `preload_months` around it.
3. On scroll/`Goto`, evict distant shards from memory; keep an LRU cache (size configurable, default 3 months).

### 7.2 Multi‑Day Span Rendering

- For each sprint/event with `[start_date, end_date]`:
  - Intersect with visible date range.
  - Render a single band row in each intersecting day cell at **band layer**.
  - Z‑order: `priority DESC`, then `order_index ASC`.

### 7.3 Ordering & Reordering

- Items store explicit `order_index` per day or per span anchor.
- Reorder operations adjust indices and persist to shard.

### 7.4 Mini‑Mode Sync

- Determine `focus_day` as the **first fully visible day header** in planner buffer (fallback: cursor day).
- Autoupdate on `WinScrolled`, `CursorMoved`, buffer changes.

---

## 8) Integration Points

- **Telescope**: custom pickers (`smartplanner.tasks`, `smartplanner.events`, etc.).
- **render-markdown.nvim**: enhance Notes display in Planner.
- **oil.nvim**: optional jump to storage roots.
- **neo-tree.nvim**: optional file explorer to year roots.
- **treesitter**: optional markdown trees for headings/sections.

---

## 9) Public Lua API (for config & extensibility)

```lua
local sp = require('smartplanner')

-- Openers
sp.open_planner(opts)   -- {date}
sp.open_calendar(opts)  -- {date, view="month"|"week"|"day"}
sp.toggle_mini(opts)

-- CRUD
sp.capture({type="task", title=..., date=..., tags={"work"}})
sp.update(id, fields)
sp.delete(id)

-- Scheduling
sp.move(id, {date=..., start_datetime=..., end_datetime=...})
sp.span(id, {start_date=..., end_date=...})  -- make multi‑day

-- Query
sp.query.tasks({status="todo", range={start=..., end=...}})
sp.query.events({range=...})
sp.query.sprints({range=...})

-- Export/Import
sp.export({scope="week", fmt="md"})
sp.import({from=path})
```

---

## 10) Module/File Structure (for the plugin repo)

```
smartplanner.nvim/
  lua/smartplanner/
    init.lua
    config.lua
    state.lua              # in‑memory caches, current view/date
    storage/
      fs.lua               # JSON shards + MD notes
      sqlite.lua           # optional
    models/
      task.lua
      event.lua
      note.lua
      sprint.lua
    views/
      planner.lua          # main buffer renderer
      calendar.lua         # month/week/day renderer
      mini.lua             # mini‑mode calendar
    ui/
      modal.lua            # capture/edit dialogs
      menu.lua             # context menus
      keymaps.lua
      telescope.lua
    util/
      date.lua             # tz handling, week calc, spans
      id.lua               # uuid
      json.lua             # robust encode/decode
      fs.lua               # paths, mkdirp, safe write
    export/
      md.lua
      csv.lua
  README.md
```

---

## 11) Edge Cases & Rules

- Spans crossing months/years must render correctly and persist in both month shards.
- Daylight‑saving changes in `Australia/Melbourne` must not corrupt stored UTC times; always store ISO‑8601 with offset.
- If two spans collide visually in a cell, stack with deterministic sorting; clamp to N rows with `+N more` roll‑up.
- Missing shards should be auto‑created on first write.
- Corrupt JSON → attempt backup/repair; never silently lose data.

---

## 12) Performance Targets

- Opening planner or calendar ≤ **80ms** with warm cache.
- Scrolling monthly view should not allocate > **5MB** transient memory per tick.
- JSON shard read/write batched (debounce writes by 300–500ms).

---

## 13) Accessibility & UX Polish

- All actions reachable via keyboard; clear focus rings.
- High‑contrast mode flag; respect current colorscheme by default.
- Glyphs fall back to ASCII if Nerdfonts unavailable.

---

## 14) Security & Privacy

- Local‑only by default; no network.
- Clear text files; user responsible for repo secrecy. Optional `gpg` hooks documented but not implemented by default.

---

## 15) Definition of Done (DOD)

- Configurable setup loads without errors on Linux/Windows.
- Planner/Calendar/Mini views render and interoperate.
- Capture modal creates Task/Event/Note/Sprint; persistence works.
- Multi‑day spans render in top band across intersecting days.
- Mini‑mode highlight follows planner viewport.
- Export (MD/CSV) works for day/week/month.
- Telescope pickers list and jump correctly.
- Unit tests for date math, shards, ordering.

---

## 16) Test Plan (Manual)

1. **Create year**: `2025` root and month shards.
2. **Add sprint**: Mon–Fri span labeled `Sprint 8`.
3. **Add daily tasks** under each day; verify calendar ordering (span above tasks).
4. **Mini‑mode sync**: open planner, scroll; confirm mini highlight moves.
5. **Cross‑month span**: create event spanning `Jan 30–Feb 2`; verify render in both shards.
6. **Reorder** items and persist `order_index`.
7. **DST boundary**: event around transition; verify displayed local time is correct.
8. **Export week** to Markdown and CSV and spot‑check.

---

## 17) Build Plan for Codex CLI (Milestones)

### M1 — Skeleton & Config
- Create repo structure; implement `init.lua`, `config.lua`, `state.lua`.
- FS storage with month shards; UUID util; basic date util.

### M2 — Planner View (Day/Week/Month headings)
- Render headings + simple lists; CRUD for tasks/notes/events; write shards.
- Keymaps for add/edit/status toggle; reorder with `order_index`.

### M3 — Calendar View (Month)
- Month grid; place single‑day items; **implement top band for multi‑day spans**.
- Sorting logic per **§2.4**.

### M4 — Mini‑Mode & Viewport Sync
- Sidebar month; highlight `focus_day`; sync on scroll/cursor.

### M5 — Modals & Telescope
- Capture modal with natural date parsing; Telescope pickers.

### M6 — Exporters & Polish
- MD/CSV export; debounce writes; error handling; docs.

### M7 — Week/Day detail views & Performance
- Week/Day view parity; optimize caches; finalize tests.

---

## 18) Acceptance Criteria (Scenario‑Driven)

- **Scenario: Sprint band above daily items**
  - Given `Sprint 8` spans Mon–Fri, when viewing the month, then a labeled band is visible across those five days **above** individual tasks.

- **Scenario: Mini‑map follows planner**
  - When I scroll the planner to `2025‑09‑18`, the mini calendar highlights `18`.

- **Scenario: Year rotation**
  - On `:SmartPlannerGoto 2026-01-02`, the plugin auto‑loads/creates `2026` roots and correct month shard.

- **Scenario: Reordering**
  - Pressing `\su` moves a task upward in the day’s list and persists `order_index`.

---

## 19) Implementation Notes (Hints for the Coding Agent)

- Prefer pure Lua; minimal deps. Optional integrations behind feature flags.
- Use `vim.schedule()` for UI updates during scroll.
- When rendering calendar bands, precalc spans into row lanes to avoid overlap thrash.
- Debounce persistence; provide `:SmartPlannerFlush` for manual sync.
- Keep all date math in UTC internally; convert for display using `os.date` with timezone offset helper.

---

## 20) Example JSON Shard (Month)

```json
{
  "month": "2025-09",
  "tasks": [
    {
      "id": "t-001",
      "title": "Implement band renderer",
      "calendar": "Work",
      "priority": 3,
      "status": "doing",
      "date": "2025-09-15",
      "order_index": 1,
      "tags": ["planner", "ui"],
      "created_at": "2025-09-07T02:10:00+10:00",
      "updated_at": "2025-09-07T02:12:00+10:00"
    }
  ],
  "events": [
    {
      "id": "e-001",
      "title": "Sprint 8",
      "calendar": "Work",
      "span": true,
      "start_date": "2025-09-15",
      "end_date": "2025-09-19",
      "priority": 2,
      "order_index": 1
    }
  ],
  "notes_index": [
    {"id":"n-101","date":"2025-09-12","path":"notes/2025-09-12-leads-sync.md","tags":["meeting"]}
  ]
}
```

---

## 21) Deliverables

- A working Neovim plugin under `smartplanner.nvim/`.
- `README.md` with setup instructions & keymaps.
- Example config for Windows & Linux, including paths.
- Sample data set for `2025-09` to exercise spans and ordering.
- Minimal test suite for date math & storage.

---

**End of specification.**




# nvim-planner — ADDENDUM: Environment Alignment & Screenshot-Derived UX

This addendum pins your **exact Neovim setup** and the **three calendar popup modes** so another AI can implement the plugin without missing context from your initial brief and screenshots.

---

## A) Your Current Neovim Environment (must support/integrate)

**Plugins in use (from your list):**  
`alpha.lua`, `autopairs.lua`, `catppuccin.lua`, `completions.lua`, `git-stuff.lua`, `gitsigns.lua`, `lsp-config.lua`, `lsp-config.lua.bkp`, `mini.lua`, `neo-tree.lua`, `none-ls.lua`, `nvim-tmux-navigation.lua`, `oil.lua`, `render-markdown.lua`, `swagger-preview.lua`, `telescope.lua`, `treesitter.lua`, `vim-test.lua`.

**Why they matter:**
- **Telescope / neo-tree** → user expects **floating, modal-first** UX; our plugin should use the same style (`nui.nvim`/`vim.ui.select`) and expose Telescope pickers.
- **render-markdown.nvim** → planner files are Markdown; our lists/checkboxes/urgency markers must render cleanly with it.
- **treesitter** → headings/sections fold cleanly; we should expose TS-friendly nodes.
- **catppuccin** → theme-driven highlighting (no hard-coded colors).
- **oil / neo-tree** → optional quick open to planner storage roots.

**Lazy.nvim bootstrap (provided by user):**
```lua
-- ~/.config/nvim/init.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("vim-options")
require("lazy").setup("plugins")
```

**Key options/binds (excerpt):**
```lua
-- ~/.config/nvim/vim-options.lua
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
vim.g.background = "light"
vim.opt.swapfile = false
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>')
vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')
vim.wo.number = true
vim.wo.relativenumber = true
```

---

## B) Calendar Popup Modes (explicit)

- **Mode 0 – Hidden**: calendar UI not visible.
- **Mode 1 – Mini View (floating, top-right)**: shows the current month with **today highlighted**; purpose is quick “what date is …” glance; navigable; clicking/enter on a day jumps to that day’s section in the Markdown planner.
- **Mode 2 – Expanded View (full-screen modal)**: toggle sub-views **Day / Week / Month**; shows **spanning items (sprints, all-day)** in a **top band**, **single-day items** below; supports a **right sidebar** for sprint notes (when a sprint is focused).

Suggested default mappings (respecting your leader and modal style):
- `\sc` → toggle Expanded Calendar (Mode 2)
- `\sm` → toggle Mini Calendar (Mode 1)
- `]d/[d` → next/prev day; `]w/[w` → next/prev week; `]m/[m` → next/prev month

---

## C) Screenshot-Derived UX (summary)

**Markdown planner screenshot:**
- Day sections like `## MONDAY 10/11/25`.
- Items with status tokens: `[✓] done`, `[X] cancelled`, `[50%] progress`, `[!!] urgent`.
- Weekend header `## WEEKEND 15,16/11/25` groups both dates.
- Emphasis line at end (bold/italic) also supported.

**Calendar spreadsheet screenshot:**
- Month header `Aug-25`, weekday band, greyed out-of-month cells.
- Green “Today!” highlight on the 25th.
- Colored all-day events (e.g., **DR Failover** red, **DR Failback** amber).
- Milestone label (“Sprint 8 to prod”) and a right-side *Sprint 8 notes* box with bullets.
- Spanning **Sprint 8** should render as a **top band** across its date range above daily items.

Encodings for these are already defined in the main spec (§20) and the two screenshot-mapped docs.

---

## D) What to Implement Differently Because of This Setup

1. **Modal-first UI** (use `nui.nvim` + Telescope pickers) to match the user’s workflow.
2. **Highlight groups only** (theme adaptive; Catppuccin-friendly) for calendar colors & urgency.
3. **Markdown parsing** to respect your exact tokens/headers and feed calendar links.
4. **Calendar modes 0/1/2** wired to keymaps above; mini-mode syncs with planner scroll.
5. **Year-scoped storage** with lazy month shards remains the persistence model.

---

## E) Hand-off Note

Attach this addendum alongside `nvim-planner-spec.md` **plus** the two screenshot-mapped docs so the coding agent has the **full context** of environment and visual intent.




