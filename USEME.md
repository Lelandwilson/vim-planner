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
- Capture: `:SmartPlannerCapture task|event|note|sprint`
- Search: `:SmartPlannerSearch tasks|events|sprints`
- Export: `:SmartPlannerExport md|csv`

## Planner Actions
- Toggle status: `\sx` on a task line (todo → doing → done)
- Reschedule: `\sr` on a task/event line
- Reorder: `\su` / `\sd` within a day’s Tasks
- Navigate days: `]d` / `[d`
- Floating Planner: `<leader>sP` (Ctrl-C or `q` to close)

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
