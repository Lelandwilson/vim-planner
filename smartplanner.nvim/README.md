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

## Keymaps
- `\\sp` open Planner; `<leader>sp` as alt
- `\\sc` open Calendar; `<leader>sc` opens or cycles Month→Week→Day while focused
- `\\sm` toggle Mini calendar
- Floating Planner: `<leader>sP` (Ctrl-C or `q` to close)
- `\\sq` toggle Quick Notes/Todos (add: `a` todo, `n` note; toggle: `x`; promote: `p`; delete: `D`)

See `lua/smartplanner/` for module responsibilities mapped to the spec.
