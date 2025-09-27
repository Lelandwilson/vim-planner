-- Calendar view (§2.2 Calendar View) — Month grid
local state = require('smartplanner.state')
local dateu = require('smartplanner.util.date')
local store = require('smartplanner.storage.fs')

local hl = require('smartplanner.ui.highlight')
local M = { buf = nil, day_index = {} }

local function ensure_buf(title)
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    vim.cmd('tabnew')
    M.buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(M.buf, 'bufhidden', 'wipe')
    local cfg = require('smartplanner.config').get().calendar or {}
    vim.api.nvim_buf_set_option(M.buf, 'filetype', cfg.filetype or 'smartplanner-calendar')
    if cfg.buftype then vim.api.nvim_buf_set_option(M.buf, 'buftype', cfg.buftype) end
    vim.api.nvim_buf_set_name(M.buf, 'SmartPlanner: ' .. title)
  end
  return M.buf
end

local function header_line(y, m)
  local month_name = os.date('%B %Y', os.time({ year = y, month = m, day = 1 }))
  return '# ' .. month_name
end

local function collect_for_month(y, m)
  local month_tbl = store.read_month(y, m)
  local start = string.format('%04d-%02d-01', y, m)
  local next_month = m == 12 and string.format('%04d-01-01', y + 1) or string.format('%04d-%02d-01', y, m + 1)
  local sprints = {}
  if store.query_sprints then
    sprints = store.query_sprints({ range = { start = start, ['end'] = next_month } }) or {}
  end
  return month_tbl, sprints
end

local function cell_summary(day, month_tbl, sprints)
  local spans, singles = {}, {}
  for _, sp in ipairs(sprints) do
    if dateu.range_intersect(sp.start_date, sp.end_date, day, day) then
      spans[#spans + 1] = 'S:' .. sp.name
    end
  end
  for _, e in ipairs(month_tbl.events or {}) do
    if e.span and dateu.range_intersect(e.start_date, e.end_date, day, day) then
      spans[#spans + 1] = 'E:' .. (e.title or e.id)
    elseif (e.date == day) and not e.span then
      local time = e.start_ts and os.date('%H:%M', e.start_ts)
      singles[#singles + 1] = time or ('E:' .. (e.title or e.id))
    end
  end
  for _, t in ipairs(month_tbl.tasks or {}) do if t.date == day then singles[#singles + 1] = 'T:' .. t.title end end
  for _, n in ipairs(month_tbl.notes_index or {}) do if n.date == day then singles[#singles + 1] = 'N:' .. (n.title or n.path) end end
  return spans, singles
end

local function day_has_urgent_task(month_tbl, day)
  for _, t in ipairs(month_tbl.tasks or {}) do
    if t.date == day and (t.priority or 0) >= 3 then return true end
  end
  return false
end

local function render_month_grid(buf, date)
  local y, m = dateu.year_month(date)
  local grid = dateu.month_grid(y, m)
  local month_tbl, sprints = collect_for_month(y, m)
  local lines = { header_line(y, m), '' }
  lines[#lines + 1] = 'Mon   Tue   Wed   Thu   Fri   Sat   Sun'
  lines[#lines + 1] = ('-'):rep(60)
  local base_line_index = #lines
  for _, week in ipairs(grid) do
    -- date row
    local drow = {}
    for _, day in ipairs(week) do
      local yy, mm, dd = day:match('(%d+)%-(%d+)%-(%d+)')
      local inmo = dateu.in_month(day, y, m)
      local lab = (inmo and string.format('%2s', dd)) or ('(' .. string.format('%2s', dd) .. ')')
      table.insert(drow, string.format('%-6s', lab))
    end
    lines[#lines + 1] = table.concat(drow, ' ')
    -- top band summaries (spans)
    local brow = {}
    for _, day in ipairs(week) do
      local span_list, _ = cell_summary(day, month_tbl, sprints)
      local band = (#span_list > 0) and table.concat(span_list, '|') or ' '
      table.insert(brow, string.sub(string.format('%-6s', band), 1, 6))
    end
    lines[#lines + 1] = table.concat(brow, ' ')
    -- single-day line
    local srow = {}
    for _, day in ipairs(week) do
      local _, singles = cell_summary(day, month_tbl, sprints)
      local text = (#singles > 0) and singles[1] or ' '
      table.insert(srow, string.sub(string.format('%-6s', text), 1, 6))
    end
    lines[#lines + 1] = table.concat(srow, ' ')
    lines[#lines + 1] = ''
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  -- Apply highlights to header and weekday row to match markdown colors
  hl.hl_line(buf, 0, 'SmartPlannerHeader')
  hl.hl_line(buf, 2, 'SmartPlannerWeekday')
  -- Highlight cells: today, bands, singles
  local today = dateu.today()
  local line_idx = base_line_index
  for w = 1, #grid do
    local week = grid[w]
    local date_line = line_idx + 1
    local band_line = line_idx + 2
    local single_line = line_idx + 3
    for i, day in ipairs(week) do
      local col_start = (i - 1) * 7
      local col_end = col_start + 6
      -- today label
      if day == today then
        hl.hl_match(buf, date_line - 1, col_start, col_end, 'SmartPlannerToday')
      end
      -- bands
      local span_list, singles = cell_summary(day, month_tbl, sprints)
      if #span_list > 0 then
        local has_sprint = false
        for _, s in ipairs(span_list) do if s:sub(1,2) == 'S:' then has_sprint = true break end end
        hl.hl_match(buf, band_line - 1, col_start, col_end, has_sprint and 'SmartPlannerSprint' or 'SmartPlannerSpan')
      end
      if #singles > 0 then
        local urgent = day_has_urgent_task(month_tbl, day)
        hl.hl_match(buf, single_line - 1, col_start, col_end, urgent and 'SmartPlannerUrgent' or 'SmartPlannerBullet')
      end
    end
    line_idx = line_idx + 4
  end
end

local function render_day_view(buf, date)
  local y, m = dateu.year_month(date)
  local month_tbl, sprints = collect_for_month(y, m)
  local lines = { '# Day — ' .. date, '' }
  M.day_index = {}
  -- Spans summary
  local spans, _ = cell_summary(date, month_tbl, sprints)
  if #spans > 0 then
    lines[#lines + 1] = 'Top band (spans):'
    for _, s in ipairs(spans) do lines[#lines + 1] = '- ' .. s end
    lines[#lines + 1] = ''
  end
  -- Detailed items
  local tasks, events, notes = {}, {}, {}
  for _, t in ipairs(month_tbl.tasks or {}) do if t.date == date then table.insert(tasks, t) end end
  for _, e in ipairs(month_tbl.events or {}) do if (e.date == date) or (e.span and dateu.range_intersect(e.start_date, e.end_date, date, date)) then table.insert(events, e) end end
  for _, n in ipairs(month_tbl.notes_index or {}) do if n.date == date then table.insert(notes, n) end end
  if #events > 0 then
    lines[#lines + 1] = '### Events'
    for _, e in ipairs(events) do
      local time = e.start_ts and not e.span and not e.allday and (os.date('%H:%M', e.start_ts) .. ' ') or ''
      lines[#lines + 1] = string.format('- %s%s', time, e.title or e.id)
      M.day_index[#lines] = { type = 'event', id = e.id, date = date }
    end
    lines[#lines + 1] = ''
  end
  -- Bind delta quick edit keys (day view)
  local function delta_line_meta()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    return M.day_index[lnum]
  end
  local function d_step(sign)
    local meta = delta_line_meta()
    if not meta then return end
    if meta.type == 'task' and sign == 0 then
      -- reuse rename for items
      local line = vim.api.nvim_get_current_line()
      local current = line:gsub('^- %[[^%]]-%]%s*', ''):gsub('^%- %s*', '')
      vim.ui.input({ prompt = 'Rename label: ', default = current }, function(newlabel)
        if not newlabel or newlabel == '' then return end
        require('smartplanner.storage').update(meta.id, { title = newlabel, label = newlabel })
        render_day_view(buf, date)
      end)
      return
    end
    if meta.type ~= 'delta_instance' then return end
    local cfg = require('smartplanner.config').get()
    local step = ((cfg.deltas and cfg.deltas.step_min) or 30) * 60
    if sign == 0 then
      vim.ui.input({ prompt = 'Set delta (hours): ', default = '0.5' }, function(val)
        local hrs = tonumber(val)
        if not hrs then return end
        require('smartplanner.storage').update_delta_instance(meta.id, { delta_sec = math.floor(hrs*3600) })
        render_day_view(buf, date)
      end)
    else
      local line = vim.api.nvim_get_current_line()
      local cur = tonumber(line:match('%+([%d%.]+)')) or 0
      local cur_sec = math.floor(cur*3600)
      local new_sec = math.max(0, cur_sec + (sign*step))
      require('smartplanner.storage').update_delta_instance(meta.id, { delta_sec = new_sec })
      render_day_view(buf, date)
    end
  end
  map(prefix..'+', function() d_step(1) end, 'Delta +step (day)')
  map(prefix..'-', function() d_step(-1) end, 'Delta -step (day)')
  map(prefix..'=', function() d_step(0) end, 'Delta set (day)')
  if #tasks > 0 then
    lines[#lines + 1] = '### Tasks'
    for _, t in ipairs(tasks) do
      local token = t.status == 'done' and '[✓]' or (t.status == 'doing' and '[~]' or '[ ]')
      lines[#lines + 1] = string.format('- %s %s', token, t.title)
      M.day_index[#lines] = { type = 'task', id = t.id, date = date }
    end
    lines[#lines + 1] = ''
  end
  if #notes > 0 then
    lines[#lines + 1] = '### Notes'
    for _, n in ipairs(notes) do
      lines[#lines + 1] = string.format('- %s', n.path or n.title or n.id)
      M.day_index[#lines] = { type = 'note', id = n.id, date = date }
    end
    lines[#lines + 1] = ''
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  hl.hl_line(buf, 0, 'SmartPlannerHeader')
  -- Day view keymaps
  local prefix = '<leader>' .. ((require('smartplanner.config').get().keymaps_prefix) or 's')
  local function map(lhs, fn, desc) vim.keymap.set('n', lhs, fn, { buffer = buf, desc = desc, silent = true }) end
  map(prefix..'t', function() require('smartplanner').capture({ type='task', date = date }) end, 'Add Task')
  map(prefix..'e', function() require('smartplanner').capture({ type='event', date = date }) end, 'Add Event')
  map(prefix..'n', function() require('smartplanner').capture({ type='note', date = date }) end, 'Add Note')
  map(prefix..'s', function() require('smartplanner').capture({ type='sprint' }) end, 'Add Sprint')
  map(prefix..'i', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local meta = M.day_index[lnum]
    local line = vim.api.nvim_get_current_line()
    local current = line:gsub('^- %[[^%]]-%]%s*', ''):gsub('^%- %s*', '')
    vim.ui.input({ prompt = 'Rename label: ', default = current }, function(newlabel)
      if not meta or not newlabel or newlabel == '' then return end
      require('smartplanner.storage').update(meta.id, { title = newlabel, label = newlabel })
      render_day_view(buf, date)
    end)
  end, 'Rename label (day)')
  map(prefix..'x', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local meta = M.day_index[lnum]
    if not meta or meta.type ~= 'task' then return end
    require('smartplanner.storage').update(meta.id, { status = 'done' })
    render_day_view(buf, date)
  end, 'Mark done (day)')
  map(prefix..'D', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local meta = M.day_index[lnum]
    if not meta then return end
    require('smartplanner.storage').delete(meta.id)
    render_day_view(buf, date)
  end, 'Delete item (day)')
  map(prefix..'r', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local meta = M.day_index[lnum]
    if not meta then return end
    vim.ui.input({ prompt = 'New date (YYYY-MM-DD): ', default = date }, function(newd)
      if not newd or newd == '' then return end
      require('smartplanner.storage').move(meta.id, { date = newd, start_date = newd })
      render_day_view(buf, date)
    end)
  end, 'Reschedule (day)')
  map(prefix..'p', function() require('smartplanner').open_planner({ date = date }) end, 'Open Planner (day)')
  map(prefix..'q', function() require('smartplanner').toggle_quicklist() end, 'Quick Inbox')
  map(prefix..'d', function() require('smartplanner.ui.delta').open() end, 'Delta Manager')
  map(prefix..'i', function() require('smartplanner.ui.delta').add_instance_for_day(date) end, 'Delta Instance (day)')
end

local function render_week_view(buf, date)
  local y, m = dateu.year_month(date)
  local grid = dateu.month_grid(y, m)
  local month_tbl, sprints = collect_for_month(y, m)
  -- find the week containing the date
  local target_week
  for _, week in ipairs(grid) do
    for _, day in ipairs(week) do if day == date then target_week = week break end end
    if target_week then break end
  end
  target_week = target_week or grid[1]
  local lines = { '# Week of ' .. target_week[1], 'Mon   Tue   Wed   Thu   Fri   Sat   Sun' }
  local brow, srow = {}, {}
  for _, day in ipairs(target_week) do
    local spans, singles = cell_summary(day, month_tbl, sprints)
    local b = (#spans > 0) and table.concat(spans, '|') or ' '
    local s = (#singles > 0) and singles[1] or ' '
    table.insert(brow, string.sub(string.format('%-6s', b), 1, 6))
    table.insert(srow, string.sub(string.format('%-6s', s), 1, 6))
  end
  lines[#lines + 1] = table.concat(brow, ' ')
  lines[#lines + 1] = table.concat(srow, ' ')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  hl.hl_line(buf, 0, 'SmartPlannerHeader')
end

function M.open(opts)
  local view = (opts and opts.view) or 'month'
  local buf = ensure_buf('Calendar (' .. view:gsub('^%l', string.upper) .. ')')
  local today = (opts and opts.date) or dateu.today()
  state.set_focus_day(today)
  if view == 'day' then
    render_day_view(buf, today)
  elseif view == 'week' then
    render_week_view(buf, today)
  else
    render_month_grid(buf, today)
  end
  -- buffer-local key to cycle view: \sc or <leader>sc
  local function cycle()
    local next_map = { month = 'week', week = 'day', day = 'month' }
    local nxt = next_map[view] or 'month'
    view = nxt
    vim.api.nvim_buf_set_name(buf, 'SmartPlanner: Calendar (' .. view:gsub('^%l', string.upper) .. ')')
    if view == 'day' then render_day_view(buf, today)
    elseif view == 'week' then render_week_view(buf, today)
    else render_month_grid(buf, today) end
  end
  vim.keymap.set('n', '\\sc', cycle, { buffer = buf, desc = 'SmartPlanner: Cycle calendar view' })
  vim.keymap.set('n', '<leader>sc', cycle, { buffer = buf, desc = 'SmartPlanner: Cycle calendar view' })
  return buf
end

return M
