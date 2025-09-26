# SmartPlanner.nvim — Comprehensive Walkthrough (SQLite-ready)

This guide walks a first-time user through installation, core views, creating and managing data (Tasks, Events, Notes, Sprints), tracking daily deltas (e.g., time in meetings), and verifying persistence. Follow the steps in order on first use.

## Install (Lazy.nvim)
- Create `~/.config/nvim/lua/plugins/smartplanner.lua` with:
```lua
return {
  {
    dir = vim.fn.expand('~/Documents/projects/vim-planner/smartplanner.nvim'),
    name = 'smartplanner.nvim',
    config = function()
      require('smartplanner').setup({
        storage = { backend = 'sqlite' },
        keymaps_prefix = 's',
        markdown = { render = true },
        telescope = { enable = true },
      })
    end,
  },
}
```
- Restart Neovim or `:Lazy sync`.

## Keymaps (prefix-aware)
With the default prefix `<leader>s`:
- Planner: `<leader>sp` open, `<leader>sf` floating (Ctrl-C/q to close)
- Calendar: `<leader>sc` Month (cycles while focused), `<leader>sw` Week, `<leader>sd` Day
- Mini calendar: `<leader>sm` toggle
- Quick inbox: `<leader>sq` (a add todo, n note, x toggle, p promote, D delete, ]d/[d next/prev day, g goto date, c clear date)
- Capture: `<leader>st` task, `<leader>se` event, `<leader>sn` note, `<leader>ss` sprint
- Planner actions: `]d`/`[d`, `<leader>sx` toggle, `<leader>sr` reschedule, `<leader>sk`/`<leader>sj` reorder, `<leader>sD` delete
- Folding: `<leader>zA` collapse all, `<leader>zW` expand current week, `<leader>zR` expand date range
- Deltas: `<leader>zd` Delta Manager, `<leader>zi` add instance for focused day

Tip: if a mapping conflicts, it’s skipped with a warning. Change `keymaps_prefix` to move the whole family (e.g., 'p').

## First-time Walkthrough (start to finish)
1) Planner (view-only pass)
   - `<leader>sp` opens “Planner — YYYY-MM” with collapsed day headings:
     `## ---- MONDAY 10/11/25 -------------------------------------`
   - Press Enter on any heading to expand/collapse. Expanding loads Tasks, Events, Notes, and Deltas for that day.

2) Calendar & Mini
   - `<leader>sc` Month; press `<leader>sc` again to cycle Month→Week→Day. Direct: `<leader>sw`/`<leader>sd`.
   - `<leader>sm` toggles a compact month that highlights Planner’s focus day.

3) Create core data
   - Sprint: `:SmartPlannerCapture sprint`
     - Name: “Sprint 9 — Incident Readiness”, Start: `2025-09-15`, End: `2025-09-26` → renders as a band above daily items.
   - Tasks: `<leader>st` → “Draft incident response plan” (Date: today); again → “Schedule tabletop exercise with team” (Date: `2025-09-18`).
   - Note: `<leader>sn` → Title “Stakeholder briefing outline” (Date: `2025-09-16`), Body “Objectives: clarify roles; Risks: auth outage; Decisions: tabletop scope”.
   - Event: `<leader>se` → “DR Failover Test” (Date: `2025-09-22`), and a span “Release Freeze” (Date: `2025-09-27,2025-09-30`).
   - Expand relevant days to verify sections; check Calendar for span vs single-day placement.

   Why use which?
   - Sprint = timebox for many items (band at the top), not a single deliverable.
   - Multi-day event = one deliverable/time span; appears in the top band.
   - Task = actionable unit; shows in daily list and supports status/priority/order.
   - Note = short day-anchored documentation.

4) Deltas (track daily metrics)
   - `<leader>zd` (Delta Manager) → `a` add:
     - Label “Time Spent in meetings”, Unit `hrs`, Per-day `2.0`, Start today, End empty (open‑ended).
   - Expand any day → see “### Deltas” with +2.00 hrs.
   - Quick add per-day on focused day: `<leader>zi` → pick entry → amount (e.g., `0.5`) → shows as “(entry)”.

5) Quick inbox (fast capture)
   - `<leader>sq` → a add quick todo, n quick note; x toggle; D delete; p promote todo to dated task; ]d/[d day preview; g goto date; c clear.
   - Use this for rapid capture while coding; promote items when ready to schedule.

6) Edit & triage in Planner
   - Toggle task status: `<leader>sx` (todo → doing → done)
   - Reschedule: `<leader>sr` (enter new date)
   - Reorder within day: `<leader>sk` (up) / `<leader>sj` (down)
   - Delete current: `<leader>sD`
   - Navigate: `]d` / `[d`
   - Folding controls: `<leader>zA` (collapse all), `<leader>zW` (expand current week), `<leader>zR` (expand range)

7) Search & export
   - Search: `:SmartPlannerSearch tasks|events|sprints`
   - Export: `:SmartPlannerExport <fmt> <scope> [date]`
     - `:SmartPlannerExport md month` (Markdown), `:SmartPlannerExport md day 2025-09-15`, `:SmartPlannerExport csv month`

8) Persistence & storage
   - SQLite DB (recommended): `~/.local/share/smartplanner/smartplanner.db` (WAL enabled)
     - Tables: items (tasks/events/notes), sprints, quick_inbox, delta_entries, delta_instances
   - Filesystem backend (legacy/fallback): `~/.local/share/smartplanner/%Y/` → months/YYYY-MM.json, sprints.json, notes/*.md, inbox.json
   - Backend switch in setup: `storage = { backend = 'sqlite' }` or `'fs'`

9) Migrate from FS to SQLite (if upgrading)
   - Run: `:SmartPlannerMigrate fs->sqlite`
     - Imports recent years’ months, sprints; notes bodies live in DB by default on this branch.
   - Verify: reopen Planner `<leader>sp`, expand a few days.

10) Customize & tips
   - Keymap prefix: set `keymaps_prefix` to move defaults (e.g., 'p' → `<leader>pp`, `<leader>pc`, …).
   - Conflicts: defaults skip and warn; define your own or set `keymaps = false` in setup to opt-out.
   - Colors: calendar/mini/headers link to render-markdown/markdown highlights.
   - Calendar filetype: defaults to `smartplanner-calendar` to avoid Markdown LSP crashes; change via setup if needed.

11) Troubleshooting
   - Calendar LSP crash: keep `smartplanner-calendar` filetype.
   - No DB: ensure `kkharji/sqlite.lua` is installed; check `:messages`.
   - Keys missing: possible conflict — adjust `keymaps_prefix` or define custom maps.
   - Day doesn’t load items: verify backend ('sqlite'), run migration if coming from FS.
