# SmartPlanner.nvim — User Guide

## Install (Lazy.nvim, local path)
- Add to `~/.config/nvim/lua/plugins/smartplanner.lua`:
```lua
return {
  {
    dir = vim.fn.expand("~/Documents/projects/vim-planner/smartplanner.nvim"),
    name = "smartplanner.nvim",
    config = function()
      require("smartplanner").setup({ keymaps = "default", markdown = { render = true }, telescope = { enable = true } })
    end,
  },
}
```
- Restart or `:Lazy sync`.

- ## Key Commands (leader-based)
- Planner: `<leader>sp` (floating: `<leader>sf`)
- Calendar: `<leader>sc` Month (cycles when focused), `<leader>sw` Week, `<leader>sd` Day
- Mini Calendar: `<leader>sm`
- Quick Notes/Todos: `<leader>sq` (panel keys: a add todo, n note, x toggle done, p promote to dated task, D delete, ]d/[d next/prev day, g goto date, c clear date, q/Ctrl-C close)
- Capture: `:SmartPlannerCapture task|event|note|sprint`
- Search: `:SmartPlannerSearch tasks|events|sprints`
- Export: `:SmartPlannerExport md|csv`
  - Supports scope and date: `:SmartPlannerExport md day 2025-09-15`, `:SmartPlannerExport csv month`

## Planner Actions
- Toggle status: `\sx` on a task line (todo → doing → done)
- Reschedule: `\sr` on a task/event line
- Reorder: `\su` / `\sd` within a day’s Tasks
- Navigate days: `]d` / `[d`
- Floating Planner: `<leader>sP` (Ctrl-C or `q` to close)

## First-time Walkthrough (comprehensive)
This guide explains each feature, where data lives on disk, and how to view → create → edit → delete. Follow in order on first use.

1) Open the Planner (View-only first)
   - Press `<leader>sp`.
   - You’ll see “Planner — YYYY-MM” with day sections like `## 2025-09-07`.
   - Where data lives: Month shard JSON at `~/.local/share/smartplanner/%Y/months/YYYY-MM.json`.
   - What it shows: Tasks, Events, Notes for each day, plus Sprint bands.

2) Calendar (View-only pass)
   - Open Month view: `<leader>sc`. Cycle to Week/Day with `<leader>sc` again.
   - Direct open: `<leader>sw` Week, `<leader>sd` Day. Mini: `<leader>sm`.
   - Where data lives: same month shard JSON; sprint list at `~/.local/share/smartplanner/%Y/sprints.json`.

3) Create a Sprint (top-band across days)
   - Run `:SmartPlannerCapture sprint`.
   - Name: type `Sprint 9 — Incident Readiness` and press Enter.
   - Start date: type today (e.g., `2025-09-15`) and Enter.
   - End date: type `2025-09-26` and Enter.
   - Why Sprint vs multi‑day task: Sprints represent a timebox (planning context) and render as a band above daily items. Multi‑day tasks represent a single work item spanning dates; they don’t convey cadence or contain other items.
   - Result: sprint band across the dates in Planner/Calendar; saved to `sprints.json`.

4) Add Two Dated Tasks
   - Run `:SmartPlannerCapture task`.
     - Title: `Draft incident response plan`
     - Date: today (e.g., `2025-09-15`)
   - Run `:SmartPlannerCapture task` again.
     - Title: `Schedule tabletop exercise with team`
     - Date: `2025-09-18`
   - Why Tasks vs Events: Tasks are actionable and get statuses; Events mark time/all‑day activities. Tasks drive your todo flow; Events block time or signal milestones.
   - Edit: in Planner, toggle `<leader>sx`, reschedule `<leader>sr`, reorder `<leader>sk`/`<leader>sj`.
   - Delete: move cursor to the task and press `<leader>sD`.
   - Stored in `months/YYYY-MM.json` under `tasks`.

5) Add a Dated Note (Markdown with front‑matter)
   - Run `:SmartPlannerCapture note`.
     - Title: `Stakeholder briefing outline`
     - Date: `2025-09-16`
     - Body: paste a short outline, e.g.:
       `Objectives: clarify roles; Risks: auth outage; Decisions: scope tabletop`
   - Result: Markdown saved under `~/.local/share/smartplanner/%Y/notes/…md`; month shard gains an index entry.
   - Edit: open the MD file (from list) and edit as normal.
   - Delete: `<leader>sD` removes the index entry (leave file on disk for safety).

6) Use the Quick Notes/Todos Panel (floating)
   - Toggle `\sq`.
   - Press `a` and type `Call vendor re. SSL expiry` → Enter (adds a quick todo).
   - Press `n` and type `Questions for tabletop: comms channel, who signs off?` → Enter (adds a quick note).
   - Move cursor to the quick todo line, press `p`, enter a date like `2025-09-17` → promotes to a dated task in the month shard.
   - Where data lives: `~/.local/share/smartplanner/%Y/inbox.json` (quick todos/notes).
   - Toggle done with `x`, delete with `D`, close with `q` or Ctrl‑C.

7) Navigate and Calendar Views
   - Next/Prev day in Planner: `]d` / `[d`.
   - Open Calendar: `<leader>sc` (Month). Inside the calendar, press `<leader>sc` to cycle Month → Week → Day; or use `<leader>sw` / `<leader>sd` directly.
   - Mini Calendar: `<leader>sm` shows a top‑right month; the current planner focus day is highlighted.

8) Edit and Reorder in Planner
   - Toggle a task status: move cursor to a task line, press `<leader>sx` (todo → doing → done).
   - Reschedule: `<leader>sr`, enter a new date (e.g., move tabletop exercise to `2025-09-19`).
   - Reorder within the day: `<leader>sk` (up) / `<leader>sj` (down).

9) Export a Report
   - `:SmartPlannerExport md month` opens a Markdown export of the current month.
   - `:SmartPlannerExport md day 2025-09-15` or `:SmartPlannerExport csv month` for other scopes.

## Where Data Is Saved
- Year root: `~/.local/share/smartplanner/%Y/`
  - `months/YYYY-MM.json` — month shard: tasks, events, notes index
  - `sprints.json` — list of sprints (multi-day bands)
  - `notes/*.md` — Markdown notes with YAML front-matter
  - `inbox.json` — Quick Notes/Todos panel data (unscheduled)

Calendar buffers use `smartplanner-calendar` filetype by default to avoid Markdown LSP crashes (configurable in setup). Planner/Quicklist use Markdown highlighting.

## Storage Layout
- Year root: `~/.local/share/smartplanner/%Y/`
  - `months/YYYY-MM.json` — tasks/events/notes index
  - `sprints.json` — spanning sprints
  - `notes/*.md` — Markdown notes with YAML front‑matter

## Tips
- Works without Telescope/render-markdown; enables extras when present.
- No hard-coded colors; adapts to your Catppuccin theme.
- Keep planner fast by limiting visible months; data is sharded per month.
- Calendar buffers use a custom filetype (`smartplanner-calendar`) to avoid Markdown LSP crashes. If you prefer attaching your Markdown LSP to the calendar, set an autocmd to change filetype, but note some servers (e.g., markdown_oxide) may not handle the grid text.
