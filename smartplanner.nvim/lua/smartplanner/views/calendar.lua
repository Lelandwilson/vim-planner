-- Calendar view (§2.2 Calendar View) — stub renderer for Month
local state = require('smartplanner.state')
local dateu = require('smartplanner.util.date')

local M = {}

local function ensure_buf(title)
  vim.cmd('tabnew')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_name(buf, 'SmartPlanner: ' .. title)
  return buf
end

function M.open(opts)
  local buf = ensure_buf('Calendar (Month)')
  local today = opts.date or dateu.today()
  state.set_focus_day(today)
  local lines = {
    '# Calendar (stub)',
    '',
    'Month view. Focus day: ' .. today,
    'Spanning items render as top bands (see §2.4).',
    'Mini-Mode highlight sync via :SmartPlannerSync.',
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

return M
