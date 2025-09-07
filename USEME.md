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
- Mini Calendar: `\sm`
- Quick Notes/Todos: `\sq` (floating). In the panel: `a` add todo, `n` add note, `x` toggle done, `p` promote todo to dated task, `D` delete, `q`/Ctrl-C close
- Capture: `:SmartPlannerCapture task|event|note|sprint`
- Search: `:SmartPlannerSearch tasks|events|sprints`
- Export: `:SmartPlannerExport md|csv`

## Planner Actions
- Toggle status: `\sx` on a task line (todo → doing → done)
- Reschedule: `\sr` on a task/event line
- Reorder: `\su` / `\sd` within a day’s Tasks
- Navigate days: `]d` / `[d`
- Floating Planner: `<leader>sP` (Ctrl-C or `q` to close)

## First-time Walkthrough
1) Install and setup via Lazy.nvim as above, then restart Neovim.
2) Open the Planner: press `\sp`. You’ll see the current month rendered with day sections.
3) Add a Sprint: run `:SmartPlannerCapture sprint`, enter a name and start/end dates. It appears as a top-band in both Planner and Calendar.
4) Add Tasks: `:SmartPlannerCapture task`, enter a title and date (e.g., today). It shows under that day’s Tasks and in the Calendar singles row.
5) Add a Note: `:SmartPlannerCapture note`, pick a date and body. The note is saved as Markdown with YAML front-matter and indexed in the month shard.
6) Calendar: press `\sc` for Month view. Cycle Month→Week→Day inside the calendar buffer using `\sc` or `<leader>sc`.
7) Mini Calendar: toggle `\sm` to keep an at-a-glance month; it highlights the planner’s focus day.
8) Quick Notes/Todos: toggle `\sq` to open a floating panel. Add quick todos/notes (`a`/`n`). Promote a quick todo to a dated task with `p` when you’re ready.
9) Triage & Edit: in Planner, toggle a task’s status with `\sx`, reschedule with `\sr`, and reorder with `\su`/`\sd`.
10) Export: `:SmartPlannerExport md` (or `csv`) to view/share.

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
