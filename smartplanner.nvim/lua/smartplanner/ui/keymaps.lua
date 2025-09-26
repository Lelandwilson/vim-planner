-- Default keymaps per §5.2
local M = {}

local function has_map(mode, lhs)
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    if m.lhs == lhs then return true end
  end
  return false
end

local function map(mode, lhs, rhs, desc)
  if has_map(mode, lhs) then
    vim.schedule(function()
      vim.notify(string.format('SmartPlanner: skipping mapping %s (conflict)', lhs), vim.log.levels.WARN)
    end)
    return
  end
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

function M.apply_defaults()
  local prefix = (require('smartplanner.config').get().keymaps_prefix or 's')
  local function P(key) return '<leader>' .. prefix .. key end
  -- Leader-first, two-letter combos
  map('n', P('p'), function() require('smartplanner').open_planner({}) end, 'SmartPlanner: Open Planner')
  map('n', P('f'), function() vim.cmd('SmartPlannerOpen planner_float') end, 'SmartPlanner: Open Planner (floating)')
  map('n', P('c'), function()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match('SmartPlanner: Calendar') then
      -- Cycle view when already in calendar
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('\\sc', true, false, true), 'n', false)
    else
      require('smartplanner').open_calendar({ view = 'month' })
    end
  end, 'SmartPlanner: Open/Cycle Calendar')
  map('n', P('c'), function() require('smartplanner').open_calendar({ view = 'month' }) end, 'SmartPlanner: Calendar Month')
  map('n', P('w'), function() require('smartplanner').open_calendar({ view = 'week' }) end, 'SmartPlanner: Calendar Week')
  map('n', P('d'), function() require('smartplanner').open_calendar({ view = 'day' }) end, 'SmartPlanner: Calendar Day')
  map('n', P('m'), function() require('smartplanner').toggle_mini({}) end, 'SmartPlanner: Toggle Mini Calendar')
  map('n', P('q'), function() require('smartplanner').toggle_quicklist() end, 'SmartPlanner: Toggle Quick Notes/Todos')
  -- Deltas
  map('n', '<leader>zd', function() require('smartplanner.ui.delta').open() end, 'SmartPlanner: Delta Manager')
  map('n', '<leader>zi', function()
    local day = require('smartplanner.state').get_focus_day() or require('smartplanner.util.date').today()
    require('smartplanner.ui.delta').add_instance_for_day(day)
  end, 'SmartPlanner: Add Delta Instance')
  -- Capture
  map('n', P('t'), function() require('smartplanner').capture({ type = 'task' }) end, 'SmartPlanner: Capture Task')
  map('n', P('e'), function() require('smartplanner').capture({ type = 'event' }) end, 'SmartPlanner: Capture Event')
  map('n', P('n'), function() require('smartplanner').capture({ type = 'note' }) end, 'SmartPlanner: Capture Note')
  map('n', P('s'), function() require('smartplanner').capture({ type = 'sprint' }) end, 'SmartPlanner: Capture Sprint')
  -- Planner actions (leader-based day nav to avoid conflicts)
  map('n', P('l'), function() require('smartplanner.views.planner').next_day() end, 'SmartPlanner: Next day')
  map('n', P('h'), function() require('smartplanner.views.planner').prev_day() end, 'SmartPlanner: Prev day')
  map('n', P('x'), function() require('smartplanner.views.planner').toggle_status() end, 'SmartPlanner: Toggle status')
  map('n', P('r'), function() require('smartplanner.views.planner').reschedule() end, 'SmartPlanner: Reschedule')
  map('n', P('k'), function() require('smartplanner.views.planner').move_up() end, 'SmartPlanner: Move up')
  map('n', P('j'), function() require('smartplanner.views.planner').move_down() end, 'SmartPlanner: Move down')
  map('n', '<leader>zA', function() require('smartplanner.views.planner').collapse_all() end, 'SmartPlanner: Collapse all days')
  map('n', '<leader>zW', function() require('smartplanner.views.planner').expand_week() end, 'SmartPlanner: Expand current week')
  map('n', '<leader>zR', function()
    local dateu = require('smartplanner.util.date')
    local start
    vim.ui.input({ prompt = 'Start date (YYYY-MM-DD): ', default = dateu.today() }, function(s) start = s end)
    if not start or start == '' then return end
    vim.schedule(function()
      local finish
      vim.ui.input({ prompt = 'End date (YYYY-MM-DD): ', default = start }, function(e)
        finish = e
        if not finish or finish == '' then return end
        require('smartplanner.views.planner').expand_range(start, finish)
      end)
    end)
  end, 'SmartPlanner: Expand date range')
  map('n', P('D'), function() require('smartplanner.views.planner').delete_current() end, 'SmartPlanner: Delete current item')
end

function M.apply_custom(defs)
  for _, m in ipairs(defs) do
    map(m[1], m[2], m[3], m[4])
  end
end

return M
