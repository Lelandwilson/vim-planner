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
  map('n', '\\sq', function() require('smartplanner').toggle_quicklist() end, 'SmartPlanner: Toggle Quick Notes/Todos')
  map('n', '<leader>sc', function()
    -- If calendar buffer, cycle; else open month
    local name = vim.api.nvim_buf_get_name(0)
    if name:match('SmartPlanner: Calendar') then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('\\sc', true, false, true), 'n', false)
    else
      require('smartplanner').open_calendar({ view = 'month' })
    end
  end, 'SmartPlanner: Open/Cycle Calendar')
  map('n', '<leader>sp', function() require('smartplanner').open_planner({}) end, 'SmartPlanner: Open Planner')
  map('n', '<leader>sP', function() vim.cmd('SmartPlannerOpen planner_float') end, 'SmartPlanner: Open Planner (floating)')
  map('n', '\\sT', function() require('smartplanner').capture({ type = 'task' }) end, 'SmartPlanner: Capture Task')
  map('n', '\\sE', function() require('smartplanner').capture({ type = 'event' }) end, 'SmartPlanner: Capture Event')
  map('n', '\\sN', function() require('smartplanner').capture({ type = 'note' }) end, 'SmartPlanner: Capture Note')
  map('n', '\\sS', function() require('smartplanner').capture({ type = 'sprint' }) end, 'SmartPlanner: Capture Sprint')
  map('n', '\\sg', function() vim.cmd('SmartPlannerGoto today') end, 'SmartPlanner: Go to date')
  map('n', ']d', function() require('smartplanner.views.planner').next_day() end, 'SmartPlanner: Next day')
  map('n', '[d', function() require('smartplanner.views.planner').prev_day() end, 'SmartPlanner: Prev day')
  map('n', ']w', function() vim.cmd('SmartPlannerGoto week') end, 'SmartPlanner: Next week')
  map('n', '[w', function() vim.cmd('SmartPlannerGoto week') end, 'SmartPlanner: Prev week')
  map('n', '\\su', function() require('smartplanner.views.planner').move_up() end, 'SmartPlanner: Move up')
  map('n', '\\sd', function() require('smartplanner.views.planner').move_down() end, 'SmartPlanner: Move down')
  map('n', '\\sr', function() require('smartplanner.views.planner').reschedule() end, 'SmartPlanner: Reschedule')
  map('n', '\\sx', function() require('smartplanner.views.planner').toggle_status() end, 'SmartPlanner: Toggle status')
end

function M.apply_custom(defs)
  for _, m in ipairs(defs) do
    map(m[1], m[2], m[3], m[4])
  end
end

return M
