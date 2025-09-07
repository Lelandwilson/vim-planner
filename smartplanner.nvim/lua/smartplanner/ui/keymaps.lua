-- Default keymaps per §5.2
local M = {}

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

function M.apply_defaults()
  -- Backslash-prefixed as in spec; users can override via setup.keymaps
  map('n', '\\sp', function() require('smartplanner').open_planner({}) end, 'SmartPlanner: Open Planner')
  map('n', '\\sc', function() require('smartplanner').open_calendar({}) end, 'SmartPlanner: Open Calendar')
  map('n', '\\sm', function() require('smartplanner').toggle_mini({}) end, 'SmartPlanner: Toggle Mini Calendar')
  map('n', '\\sT', function() require('smartplanner').capture({ type = 'task' }) end, 'SmartPlanner: Capture Task')
  map('n', '\\sE', function() require('smartplanner').capture({ type = 'event' }) end, 'SmartPlanner: Capture Event')
  map('n', '\\sN', function() require('smartplanner').capture({ type = 'note' }) end, 'SmartPlanner: Capture Note')
  map('n', '\\sS', function() require('smartplanner').capture({ type = 'sprint' }) end, 'SmartPlanner: Capture Sprint')
  map('n', '\\sg', function() vim.cmd('SmartPlannerGoto today') end, 'SmartPlanner: Go to date')
  map('n', ']d', function() vim.cmd('SmartPlannerGoto today') end, 'SmartPlanner: Next day (stub)')
  map('n', '[d', function() vim.cmd('SmartPlannerGoto today') end, 'SmartPlanner: Prev day (stub)')
  map('n', ']w', function() vim.cmd('SmartPlannerGoto week') end, 'SmartPlanner: Next week (stub)')
  map('n', '[w', function() vim.cmd('SmartPlannerGoto week') end, 'SmartPlanner: Prev week (stub)')
  map('n', '\\su', function() vim.notify('Move up (stub)') end, 'SmartPlanner: Move up')
  map('n', '\\sd', function() vim.notify('Move down (stub)') end, 'SmartPlanner: Move down')
  map('n', '\\sr', function() vim.notify('Reschedule (stub)') end, 'SmartPlanner: Reschedule')
  map('n', '\\sx', function() vim.notify('Toggle status (stub)') end, 'SmartPlanner: Toggle status')
end

function M.apply_custom(defs)
  for _, m in ipairs(defs) do
    map(m[1], m[2], m[3], m[4])
  end
end

return M
