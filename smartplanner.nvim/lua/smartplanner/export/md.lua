-- Markdown exporter (§3.2, §9 export)
local store = require('smartplanner.storage.fs')
local dateu = require('smartplanner.util.date')

local M = {}

function M.export(opts)
  local scope = opts.scope or 'week'
  local day = opts.date or dateu.today()
  local y, m = dateu.year_month(day)
  local month = store.read_month(y, m)
  local lines = { '# SmartPlanner Export (' .. scope .. ')', '' }
  if scope == 'day' then
    local function add_for(d)
      lines[#lines + 1] = '## ' .. d
      for _, e in ipairs(month.events or {}) do if (e.date == d) or (e.span and dateu.range_intersect(e.start_date, e.end_date, d, d)) then lines[#lines + 1] = '- Event: ' .. (e.title or e.id) end end
      for _, t in ipairs(month.tasks or {}) do if t.date == d then lines[#lines + 1] = '- Task: ' .. t.title end end
      for _, n in ipairs(month.notes_index or {}) do if n.date == d then lines[#lines + 1] = '- Note: ' .. (n.path or n.id) end end
      lines[#lines + 1] = ''
    end
    add_for(day)
  else
    -- week or month: keep simple; export current month
    for _, d in ipairs(dateu.month_days(y, m)) do
      lines[#lines + 1] = '## ' .. d
      for _, e in ipairs(month.events or {}) do if (e.date == d) or (e.span and dateu.range_intersect(e.start_date, e.end_date, d, d)) then lines[#lines + 1] = '- Event: ' .. (e.title or e.id) end end
      for _, t in ipairs(month.tasks or {}) do if t.date == d then lines[#lines + 1] = '- Task: ' .. t.title end end
      for _, n in ipairs(month.notes_index or {}) do if n.date == d then lines[#lines + 1] = '- Note: ' .. (n.path or n.id) end end
      lines[#lines + 1] = ''
    end
  end
  vim.cmd('new')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return true
end

return M
