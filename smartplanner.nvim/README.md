# smartplanner.nvim (alias: nvim-planner.lua)

A modal-first planner for Neovim that unifies daily planning, todos, notes, sprints, and a calendar.

- Style: floating modals, Markdown-first, theme-adaptive, keyboard-centric.
- Integrations: Telescope, render-markdown, treesitter, neo-tree, Catppuccin-friendly highlights.

## Setup

```lua
-- Lazy.nvim
{
  "local/smartplanner.nvim",
  config = function()
    require("smartplanner").setup({
      -- SQLite backend recommended on sqlite branch
      storage = { backend = "sqlite" },
      -- Leader prefix for keymaps: default 's' → <leader>sp, <leader>sc, etc.
      keymaps_prefix = "s",
      -- Event defaults (timed events)
      events = { default_start = "09:00", default_duration_min = 60 },
      telescope = { enable = true },
      markdown = { render = true },
      keymaps = "default",
    })
  end,
}
```

## Commands
- `:SmartPlannerOpen [view=planner|calendar|mini] [date=YYYY-MM-DD]`
- `:SmartPlannerOpen calendar [month|week|day] [date?]`
- `:SmartPlannerOpen planner_float` — open planner in a floating modal (Ctrl-C to close)
- `:SmartPlannerOpen quick` — toggle Quick Notes/Todos (floating)
- `:SmartPlannerCapture [type=task|event|note|sprint] [date=...]`
- `:SmartPlannerGoto [today|week|month|YYYY-MM-DD]`
- `:SmartPlannerSearch [tasks|events|notes|sprints] [query=...]`
- `:SmartPlannerExport ...`
- `:SmartPlannerConfig`
- `:SmartPlannerSync`
- `:SmartPlannerMigrate fs->sqlite` — import existing JSON shards to SQLite (sqlite branch)

## Keymaps (leader-based, prefix-aware)
- Planner: `<leader>sp` open; `<leader>sf` floating (Ctrl-C/`q`)
- Calendar: `<leader>sc` Month (cycles when focused), `<leader>sw` Week, `<leader>sd` Day
- Mini: `<leader>sm` toggle; Quick Inbox: `<leader>sq` (a add todo, n note, x toggle, p promote, D delete, ]d/[d day, g goto date, c clear)
- Capture: `<leader>st` task, `<leader>se` event, `<leader>sn` note, `<leader>ss` sprint
- Planner actions: `<leader>sl` next day / `<leader>sh` prev day, `<leader>sx` toggle status, `<leader>sr` reschedule, `<leader>sk`/`<leader>sj` reorder, `<leader>sD` delete
- Folding (Planner): `<leader>zA` collapse all, `<leader>zW` expand current week, `<leader>zR` expand date range
- Deltas: `<leader>zd` Delta Manager, `<leader>zi` add per-day instance for focused day

Notes
- Default keymaps skip if there is a conflict and warn. Change `keymaps_prefix` (e.g., to 'p') to move the whole family.

## Planner UX (sqlite branch)
- Headings render collapsed with fixed-width dashes: `## ---- MONDAY 10/11/25 --------`
- Expand a day with Enter to load Tasks, Events, Notes, and Deltas; empty days show "(no items)".
- Planner remembers your last day; reopening centers the cursor there.

## Events with time
- Use `<leader>se` and enter When as `YYYY-MM-DD HH:MM` or a range `start,end`.
- Defaults come from `events.default_start` and `events.default_duration_min`.

See `lua/smartplanner/` for module responsibilities mapped to the spec.

## Export
- Command: `:SmartPlannerExport <fmt> <scope> [date]`
  - Examples: `:SmartPlannerExport md day 2025-09-15`, `:SmartPlannerExport csv month`
