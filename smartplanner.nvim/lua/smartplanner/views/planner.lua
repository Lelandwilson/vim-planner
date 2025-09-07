-- Planner view (§2.2 Planner View) — stub renderer
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
  local buf = ensure_buf('Planner')
  local today = opts.date or dateu.today()
  state.set_focus_day(today)
  local lines = {
    '# Planner (stub)',
    '',
    'Focus day: ' .. today,
    '',
    'Use :SmartPlannerCapture to add items.',
    'See nvim-planner-spec.md §6.1 for target structure.',
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

function M.goto_date(arg)
  local d = arg
  if arg == 'today' or not arg then d = require('smartplanner.util.date').today() end
  state.set_focus_day(d)
  vim.notify('Goto ' .. d .. ' (planner stub)')
end

return M
