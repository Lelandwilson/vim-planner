-- Default keymaps per §5.2
local M = {}

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

function M.apply_defaults()
  -- Leader-first, two-letter combos
  map('n', '<leader>sp', function() require('smartplanner').open_planner({}) end, 'SmartPlanner: Open Planner')
  map('n', '<leader>sf', function() vim.cmd('SmartPlannerOpen planner_float') end, 'SmartPlanner: Open Planner (floating)')
  map('n', '<leader>sc', function()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match('SmartPlanner: Calendar') then
      -- Cycle view when already in calendar
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('\\sc', true, false, true), 'n', false)
    else
      require('smartplanner').open_calendar({ view = 'month' })
    end
  end, 'SmartPlanner: Open/Cycle Calendar')
  map('n', '<leader>sc', function() require('smartplanner').open_calendar({ view = 'month' }) end, 'SmartPlanner: Calendar Month')
  map('n', '<leader>sw', function() require('smartplanner').open_calendar({ view = 'week' }) end, 'SmartPlanner: Calendar Week')
  map('n', '<leader>sd', function() require('smartplanner').open_calendar({ view = 'day' }) end, 'SmartPlanner: Calendar Day')
  map('n', '<leader>sm', function() require('smartplanner').toggle_mini({}) end, 'SmartPlanner: Toggle Mini Calendar')
  map('n', '<leader>sq', function() require('smartplanner').toggle_quicklist() end, 'SmartPlanner: Toggle Quick Notes/Todos')
  -- Capture
  map('n', '<leader>st', function() require('smartplanner').capture({ type = 'task' }) end, 'SmartPlanner: Capture Task')
  map('n', '<leader>se', function() require('smartplanner').capture({ type = 'event' }) end, 'SmartPlanner: Capture Event')
  map('n', '<leader>sn', function() require('smartplanner').capture({ type = 'note' }) end, 'SmartPlanner: Capture Note')
  map('n', '<leader>ss', function() require('smartplanner').capture({ type = 'sprint' }) end, 'SmartPlanner: Capture Sprint')
  -- Planner actions
  map('n', ']d', function() require('smartplanner.views.planner').next_day() end, 'SmartPlanner: Next day')
  map('n', '[d', function() require('smartplanner.views.planner').prev_day() end, 'SmartPlanner: Prev day')
  map('n', '<leader>sx', function() require('smartplanner.views.planner').toggle_status() end, 'SmartPlanner: Toggle status')
  map('n', '<leader>sr', function() require('smartplanner.views.planner').reschedule() end, 'SmartPlanner: Reschedule')
  map('n', '<leader>sk', function() require('smartplanner.views.planner').move_up() end, 'SmartPlanner: Move up')
  map('n', '<leader>sj', function() require('smartplanner.views.planner').move_down() end, 'SmartPlanner: Move down')
end

function M.apply_custom(defs)
  for _, m in ipairs(defs) do
    map(m[1], m[2], m[3], m[4])
  end
end

return M
