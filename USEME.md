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

## Key Commands
- Open Planner: `\sp`
- Open Calendar: `\sc` (month). Week/Day: `:SmartPlannerOpen calendar week|day`. In a calendar buffer, `<leader>sc` cycles Month→Week→Day.
- Calendar shortcuts: `<leader>scm` month, `<leader>scw` week, `<leader>scd` day
- Mini Calendar: `\sm`
- Quick Notes/Todos: `\sq` (floating). In the panel: `a` add todo, `n` add note, `x` toggle done, `p` promote todo to dated task, `D` delete, `q`/Ctrl-C close
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

## First-time Walkthrough (step-by-step)
Follow these exact steps to create a sprint, add tasks/notes, use the quick panel, and navigate/calendar/export.

1) Open the Planner
   - Press `\sp`.
   - You’ll see “Planner — YYYY-MM” with day sections like `## 2025-09-07`.

2) Create a Sprint (top-band across days)
   - Run `:SmartPlannerCapture sprint`.
   - Name: type `Sprint 9 — Incident Readiness` and press Enter.
   - Start date: type today (e.g., `2025-09-15`) and Enter.
   - End date: type `2025-09-26` and Enter.
   - Result: the sprint band shows at the top of the Planner days it spans and appears in the Calendar’s band row.

3) Add Two Dated Tasks
   - Run `:SmartPlannerCapture task`.
     - Title: `Draft incident response plan`
     - Date: today (e.g., `2025-09-15`)
   - Run `:SmartPlannerCapture task` again.
     - Title: `Schedule tabletop exercise with team`
     - Date: `2025-09-18`
   - Result: tasks appear under their day’s “### Tasks” and in Calendar’s singles row.

4) Add a Dated Note (Markdown with front‑matter)
   - Run `:SmartPlannerCapture note`.
     - Title: `Stakeholder briefing outline`
     - Date: `2025-09-16`
     - Body: paste a short outline, e.g.:
       `Objectives: clarify roles; Risks: auth outage; Decisions: scope tabletop`
   - Result: a Markdown file is written under the year’s `notes/` folder and linked in the day’s “### Notes”.

5) Use the Quick Notes/Todos Panel (floating)
   - Toggle `\sq`.
   - Press `a` and type `Call vendor re. SSL expiry` → Enter (adds a quick todo).
   - Press `n` and type `Questions for tabletop: comms channel, who signs off?` → Enter (adds a quick note).
   - Move cursor to the quick todo line, press `p`, enter a date like `2025-09-17` → it’s promoted to a dated task and will show in Planner/Calendar.
   - Toggle done with `x`, delete with `D`, close with `q` or Ctrl‑C.

6) Navigate and Calendar Views
   - Next/Prev day in Planner: `]d` / `[d`.
   - Open Calendar: `\sc` (Month). Inside the calendar, press `\sc` (or `<leader>sc`) to cycle Month → Week → Day.
   - Mini Calendar: `\sm` shows a top‑right month; the current planner focus day is highlighted.

7) Edit and Reorder in Planner
   - Toggle a task status: move cursor to a task line, press `\sx` (todo → doing → done).
   - Reschedule: `\sr`, enter a new date (e.g., move tabletop exercise to `2025-09-19`).
   - Reorder within the day: `\su` / `\sd`.

8) Export a Report
   - `:SmartPlannerExport md` opens a Markdown export of the current month (or set scope in code).
   - `:SmartPlannerExport csv` opens a CSV snapshot of events/tasks/notes.

## Where Data Is Saved
- Year root: `~/.local/share/smartplanner/%Y/`
  - `months/YYYY-MM.json` — month shard: tasks, events, notes index
  - `sprints.json` — list of sprints (multi-day bands)
  - `notes/*.md` — Markdown notes with YAML front-matter
  - `inbox.json` — Quick Notes/Todos panel data (unscheduled)

Calendar buffers use `smartplanner-calendar` filetype to avoid Markdown LSP crashes. Planner and Quicklist use Markdown highlighting but remain modal-first.

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
