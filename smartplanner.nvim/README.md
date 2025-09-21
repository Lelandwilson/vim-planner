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
      default_calendar = "Work",
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

## Keymaps (leader-based)
- `<leader>sp` open Planner; `<leader>sf` floating Planner (Ctrl-C/`q` to close)
- `<leader>sc` Calendar Month (when focused, cycles Month→Week→Day)
- `<leader>sw` Calendar Week; `<leader>sd` Calendar Day
- `<leader>sm` toggle Mini calendar; `<leader>sq` toggle Quick Notes/Todos (a add todo, n note, x toggle, p promote, D delete)

See `lua/smartplanner/` for module responsibilities mapped to the spec.

## Export
- Command: `:SmartPlannerExport <fmt> <scope> [date]`
  - Examples: `:SmartPlannerExport md day 2025-09-15`, `:SmartPlannerExport csv month`
