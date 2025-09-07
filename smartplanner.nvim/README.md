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

## Commands (stubs)
- `:SmartPlannerOpen [view=planner|calendar|mini] [date=YYYY-MM-DD]`
- `:SmartPlannerCapture [type=task|event|note|sprint] [date=...]`
- `:SmartPlannerGoto [today|week|month|YYYY-MM-DD]`
- `:SmartPlannerSearch [tasks|events|notes|sprints] [query=...]`
- `:SmartPlannerExport ...`
- `:SmartPlannerConfig`
- `:SmartPlannerSync`

See `lua/smartplanner/` for module responsibilities mapped to the spec.
