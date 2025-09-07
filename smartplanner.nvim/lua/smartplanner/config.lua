local M = {}

-- Defaults per §4 Config API
local defaults = {
  default_calendar = 'Work',
  calendars = {
    Work = { root = vim.fn.stdpath('data') .. '/smartplanner/Work' },
    Personal = { root = vim.fn.stdpath('data') .. '/smartplanner/Personal' },
  },
  year_root = vim.fn.stdpath('data') .. '/smartplanner/%Y',
  float_style = { border = 'rounded', width = 92, height = 24, winblend = 0, zindex = 50 },
  storage = { backend = 'fs', preload_months = 1 },
  timezone = 'Australia/Melbourne',
  telescope = { enable = true },
  markdown = { render = true },
  keymaps = 'default',
}

function M.get()
  return M._cfg or defaults
end

function M.setup(opts)
  M._cfg = vim.tbl_deep_extend('force', defaults, opts or {})
  return M._cfg
end

function M.open_help()
  vim.cmd('new')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'SmartPlanner Config (stub)',
    'Edit your setup() call in Lazy.nvim. See nvim-planner-spec.md §4.',
  })
end

return M
