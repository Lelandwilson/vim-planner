-- Planner view (§2.2 Planner View)
local state = require('smartplanner.state')
local dateu = require('smartplanner.util.date')
local store = require('smartplanner.storage')

local M = { buf = nil, line_index = {} }

-- Build a day header with a consistent total width by padding dashes
local function header_for_day(day)
  local target = 80 -- total characters for the header line
  local prefix = '## ---- '
  local core = string.format('%s %s', dateu.day_name(day), dateu.ddmmyy(day))
  local base = prefix .. core .. ' '
  local pad = target - #base
  if pad < 1 then pad = 1 end
  return base .. string.rep('-', pad)
end

local function header_day_from_line(line)
  local dd, mm, yy = line:match('(%d%d)/(%d%d)/(%d%d)')
  if not dd then return nil end
  local yyyy = tostring(2000 + tonumber(yy))
  return string.format('%s-%s-%s', yyyy, mm, dd)
end

local function find_header_up(buf, lnum)
  while lnum > 1 do
    local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
    if line and line:match('^## %-%-') then return lnum, line end
    lnum = lnum - 1
  end
  return nil
end

local function ensure_buf(title)
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    vim.cmd('tabnew')
    M.buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(M.buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
    vim.api.nvim_buf_set_name(M.buf, 'SmartPlanner: ' .. title)
    -- Make headings foldable with Treesitter if available
    pcall(vim.api.nvim_buf_set_option, M.buf, 'foldenable', true)
    pcall(vim.api.nvim_buf_set_option, M.buf, 'foldlevel', 1)
    local ok = pcall(function()
      vim.api.nvim_buf_set_option(M.buf, 'foldmethod', 'expr')
      vim.api.nvim_buf_set_option(M.buf, 'foldexpr', 'nvim_treesitter#foldexpr()')
    end)
    if not ok then
      -- Fallback minimal folding by indent
      pcall(vim.api.nvim_buf_set_option, M.buf, 'foldmethod', 'indent')
    end
  end
  return M.buf
end

local function sort_items(tasks, events, notes)
  table.sort(events, function(a, b)
    if (a.span or a.allday) ~= (b.span or b.allday) then return (a.span or a.allday) end
    if (a.priority or 0) ~= (b.priority or 0) then return (a.priority or 0) > (b.priority or 0) end
    return (a.order_index or 0) < (b.order_index or 0)
  end)
  table.sort(tasks, function(a, b)
    if (a.priority or 0) ~= (b.priority or 0) then return (a.priority or 0) > (b.priority or 0) end
    if (a.order_index or 0) ~= (b.order_index or 0) then return (a.order_index or 0) < (b.order_index or 0) end
    return (a.title or '') < (b.title or '')
  end)
  table.sort(notes, function(a, b) return (a.title or a.path or '') < (b.title or b.path or '') end)
end

local function render_day(lines, day, month_tbl, sprints)
  lines[#lines + 1] = header_for_day(day)
  -- Split items for this day
  local tasks, events, notes = {}, {}, {}
  for _, t in ipairs(month_tbl.tasks or {}) do if t.date == day then tasks[#tasks + 1] = t end end
  for _, e in ipairs(month_tbl.events or {}) do
    if (e.date == day) or (e.span and dateu.range_intersect(e.start_date, e.end_date, day, day)) then
      events[#events + 1] = e
    end
  end
  for _, n in ipairs(month_tbl.notes_index or {}) do if n.date == day then notes[#notes + 1] = n end end
  -- Include sprints intersecting this day
  for _, sp in ipairs(sprints or {}) do
    if dateu.range_intersect(sp.start_date, sp.end_date, day, day) then
      events[#events + 1] = { id = sp.id, title = sp.name, span = true, start_date = sp.start_date, end_date = sp.end_date, priority = 2 }
    end
  end
  sort_items(tasks, events, notes)
  -- Events (spans/allday top)
  if #events > 0 then
    lines[#lines + 1] = '### Events'
    for _, e in ipairs(events) do
      local badge = e.span and '[S]' or (e.allday and '[A]' or '[ ]')
      lines[#lines + 1] = string.format('- %s %s', badge, e.title or e.id)
      M.line_index[#lines] = { type = 'event', id = e.id, date = day }
    end
    lines[#lines + 1] = ''
  end
  if #tasks > 0 then
    lines[#lines + 1] = '### Tasks'
    for _, t in ipairs(tasks) do
      local token = t.status == 'done' and '[✓]' or (t.status == 'doing' and '[~]' or (t.priority and t.priority > 2 and '[!!]' or '[ ]'))
      lines[#lines + 1] = string.format('- %s %s', token, t.title)
      M.line_index[#lines] = { type = 'task', id = t.id, date = day }
    end
    lines[#lines + 1] = ''
  end
  if #notes > 0 then
    lines[#lines + 1] = '### Notes'
    for _, n in ipairs(notes) do
      lines[#lines + 1] = string.format('- %s', n.path)
      M.line_index[#lines] = { type = 'note', id = n.id, date = day, path = n.path }
    end
    lines[#lines + 1] = ''
  end
  -- Deltas section (sqlite backend populates; fs backend returns empty)
  local deltas, instances = {}, {}
  local ok, rows, inst = pcall(function()
    if store.query_deltas_for_day then
      local r, i = store.query_deltas_for_day(day)
      return r or {}, i or {}
    end
  end)
  if ok and rows then deltas, instances = rows, inst end
  if (#deltas > 0) or (#instances > 0) then
    lines[#lines + 1] = '### Deltas'
    for _, d in ipairs(deltas) do
      local value = (d.delta_sec or 0) / 3600.0
      lines[#lines + 1] = string.format('- %s: +%.2f %s', d.label or 'Delta', value, d.time_unit or 'hrs')
    end
    for _, di in ipairs(instances) do
      local value = (di.delta_sec or 0) / 3600.0
      lines[#lines + 1] = string.format('- %s (entry): +%.2f %s', di.label or 'Delta', value, di.time_unit or 'hrs')
    end
    lines[#lines + 1] = ''
  end
end

local function load_sprints(year)
  local s, _ = (function()
    local ok, tbl = pcall(function()
      local root = (require('smartplanner.config').get().year_root):gsub('%%Y', tostring(year))
      local data = require('smartplanner.util.fs').read_file(root .. '/sprints.json')
      return data and (require('smartplanner.util.json').decode(data) or { sprints = {} }) or { sprints = {} }
    end)
    if ok then return tbl, true else return { sprints = {} }, false end
  end)()
  return s.sprints or {}
end

local function render_month(buf, date)
  local y, m = dateu.year_month(date)
  local days = dateu.month_days(y, m)
  M.line_index = {}
  local lines = { string.format('# Planner — %04d-%02d', y, m), '' }
  -- headings only (collapsed by default)
  for _, d in ipairs(days) do
    lines[#lines + 1] = header_for_day(d)
    -- leave collapsed; expand on demand
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  -- buffer-local mappings for toggling
  local function toggle_current_day()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    -- find header line
    while lnum > 1 do
      local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
      if line:match('^## %-%-') then break end
      lnum = lnum - 1
    end
    local header = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
    local dd, mm, yy = header:match('(%d%d)/(%d%d)/(%d%d)')
    if not dd then return end
    local yyyy = tostring(2000 + tonumber(yy))
    local day = string.format('%s-%s-%s', yyyy, mm, dd)
    -- check if already expanded: if the next line is not another header, it's expanded
    local next_line = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1]
    if next_line and not next_line:match('^## %-%-') then
      -- collapse: delete until next header or end
      local end_ln = lnum
      local total = vim.api.nvim_buf_line_count(buf)
      local i = lnum + 1
      while i <= total do
        local s = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
        if s:match('^## %-%-') then break end
        end_ln = i
        i = i + 1
      end
      if end_ln > lnum then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, lnum, end_ln, false, {})
          end
        end)
      end
      return
    end
    -- expand: fetch from storage and insert sections
    local daydata
    if store.query_day then
      daydata = store.query_day(day)
    else
      local y, m = dateu.year_month(day)
      local month_tbl = store.read_month(y, m)
      daydata = { tasks = {}, events = {}, notes = {} }
      for _, t in ipairs(month_tbl.tasks or {}) do if t.date == day then table.insert(daydata.tasks, t) end end
      for _, e in ipairs(month_tbl.events or {}) do if (e.date == day) or (e.span and dateu.range_intersect(e.start_date, e.end_date, day, day)) then table.insert(daydata.events, e) end end
      for _, n in ipairs(month_tbl.notes_index or {}) do if n.date == day then table.insert(daydata.notes, n) end end
    end
    local sprints = store.query_sprints and store.query_sprints({ range = { start = day, ['end'] = day } }) or {}
    local lines_ins = {}
    local idx_map = {}
    local tasks, events, notes = daydata.tasks or {}, daydata.events or {}, daydata.notes or {}
    -- include sprints as events
    for _, sp in ipairs(sprints) do
      local sd = sp.start_date or (sp.start_ts and os.date('%Y-%m-%d', sp.start_ts))
      local ed = sp.end_date or (sp.end_ts and os.date('%Y-%m-%d', sp.end_ts))
      if sd and ed and dateu.range_intersect(sd, ed, day, day) then
        table.insert(events, { id = sp.id, title = sp.name, span = true, start_date = sd, end_date = ed, priority = sp.priority or 0 })
      end
    end
    -- Deltas
    local deltas, inst = {}, {}
    local ok, r1, r2 = pcall(function()
      if store.query_deltas_for_day then return store.query_deltas_for_day(day) end
    end)
    if ok and r1 then deltas, inst = r1, r2 end
    -- build sections
    if #events > 0 then
      table.insert(lines_ins, '### Events')
      for _, e in ipairs(events) do
        local badge = e.span and '[S]' or (e.allday and '[A]' or '[ ]')
        local time = (e.start_ts and not e.span and not e.allday) and (os.date('%H:%M', e.start_ts) .. ' ') or ''
        table.insert(lines_ins, string.format('- %s %s%s', badge, time, e.title or e.id))
        idx_map[#lines_ins] = { type = 'event', id = e.id, date = day }
      end
      table.insert(lines_ins, '')
    end
    if #tasks > 0 then
      table.insert(lines_ins, '### Tasks')
      for _, t in ipairs(tasks) do
        local token = t.status == 'done' and '[✓]' or (t.status == 'doing' and '[~]' or (t.priority and t.priority > 2 and '[!!]' or '[ ]'))
        table.insert(lines_ins, string.format('- %s %s', token, t.title))
        idx_map[#lines_ins] = { type = 'task', id = t.id, date = day }
      end
      table.insert(lines_ins, '')
    end
    if #notes > 0 then
      table.insert(lines_ins, '### Notes')
      for _, n in ipairs(notes) do
        table.insert(lines_ins, string.format('- %s', n.path or n.title or n.id))
        idx_map[#lines_ins] = { type = 'note', id = n.id, date = day, path = n.path }
      end
      table.insert(lines_ins, '')
    end
  if (#inst > 0) then
    table.insert(lines_ins, '### Deltas')
    for _, di in ipairs(inst) do
      local value = (di.delta_sec or 0) / 3600.0
      table.insert(lines_ins, string.format('- %s (entry): +%.2f %s', di.label or 'Delta', value, di.time_unit or 'hrs'))
    end
    table.insert(lines_ins, '')
  end
  if #lines_ins == 0 then
    table.insert(lines_ins, '_(no items)_')
    table.insert(lines_ins, '')
  end
    if #lines_ins > 0 then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_set_lines(buf, lnum, lnum, false, lines_ins)
          local base = lnum + 1
          for off, meta in pairs(idx_map) do
            M.line_index[base + off - 1] = meta
          end
        end
      end)
    end
  end
  vim.keymap.set('n', '<CR>', toggle_current_day, { buffer = buf, desc = 'SmartPlanner: toggle day' })
end

function M.open(opts)
  local buf = ensure_buf('Planner')
  local remembered = require('smartplanner.state').get_last_planner_day()
  local day = opts.date or remembered or dateu.today()
  state.set_focus_day(day)
  render_month(buf, day)
  -- Sync mini on scroll/cursor
  vim.api.nvim_create_autocmd({ 'WinScrolled', 'CursorMoved' }, {
    buffer = buf,
    callback = function()
      local cur = vim.api.nvim_win_get_cursor(0)[1]
      local hln, line = find_header_up(buf, cur)
      if line then
        local d = header_day_from_line(line)
        if d then
          state.set_focus_day(d)
          state.set_last_planner_day(d)
        end
      end
      local ok, mini = pcall(require, 'smartplanner.views.mini')
      if ok then mini.sync_focus() end
    end,
  })
  -- Center on remembered day header
  local total = vim.api.nvim_buf_line_count(buf)
  for i = 1, total do
    local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
    if line and line:match('^## %-%-') then
      local d = header_day_from_line(line)
      if d == day then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        vim.cmd('normal! zz')
        break
      end
    end
  end
  return buf
end

function M.goto_date(arg)
  local d = arg
  if arg == 'today' or not arg then d = dateu.today() end
  state.set_focus_day(d)
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    render_month(M.buf, d)
  end
end

local function current_item()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  return M.line_index[lnum]
end

function M.toggle_status()
  local item = current_item()
  if not item or item.type ~= 'task' then return end
  -- naive cycle: todo -> doing -> done -> todo
  local update
  local now = require('smartplanner.storage')
  -- fetch and toggle via update
  local next_status = { todo = 'doing', doing = 'done', done = 'todo' }
  update = now.update(item.id, { status = next_status['todo'] }) -- default
  -- Try to detect current from rendered line
  local line = vim.api.nvim_get_current_line()
  local cur = line:match('%[(.-)%]')
  local map = { ['✓'] = 'done', ['~'] = 'doing', ['!!'] = 'todo', [' '] = 'todo' }
  local s = map[cur] or 'todo'
  local ns = next_status[s] or 'todo'
  now.update(item.id, { status = ns })
  M.goto_date(state.get_focus_day() or dateu.today())
end

function M.reschedule()
  local item = current_item()
  if not item or (item.type ~= 'task' and item.type ~= 'event') then return end
  vim.ui.input({ prompt = 'New date (YYYY-MM-DD): ', default = state.get_focus_day() or dateu.today() }, function(val)
    if not val or val == '' then return end
    require('smartplanner.storage').move(item.id, { date = val, start_date = val })
    M.goto_date(val)
  end)
end

function M.move_up()
  local item = current_item()
  if not item or item.type ~= 'task' then return end
  require('smartplanner.storage').reorder_task(item.date, item.id, 'up')
  M.goto_date(item.date)
end

function M.move_down()
  local item = current_item()
  if not item or item.type ~= 'task' then return end
  require('smartplanner.storage').reorder_task(item.date, item.id, 'down')
  M.goto_date(item.date)
end

function M.next_day()
  local d = state.get_focus_day() or dateu.today()
  local nd = dateu.add_days(d, 1)
  M.goto_date(nd)
end

function M.prev_day()
  local d = state.get_focus_day() or dateu.today()
  local pd = dateu.add_days(d, -1)
  M.goto_date(pd)
end

function M.delete_current()
  local item = current_item()
  if not item then return end
  local ok = require('smartplanner.storage').delete(item.id)
  if ok then
    vim.notify('Deleted item', vim.log.levels.INFO)
    M.goto_date(item.date or (state.get_focus_day() or dateu.today()))
  else
    vim.notify('Delete failed', vim.log.levels.ERROR)
  end
end

-- Helper: toggle at a given header line by simulating <CR>
local function toggle_at_line(lnum)
  if not M.buf then return end
  local cur = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
  vim.api.nvim_win_set_cursor(0, cur)
end

local function line_is_header(lnum)
  local s = vim.api.nvim_buf_get_lines(M.buf, lnum - 1, lnum, false)[1]
  return s and s:match('^## %-%-') ~= nil
end

local function header_is_expanded(lnum)
  local next_line = vim.api.nvim_buf_get_lines(M.buf, lnum, lnum + 1, false)[1]
  return next_line and next_line:match('^### ') ~= nil
end

function M.collapse_all()
  if not M.buf then return end
  local total = vim.api.nvim_buf_line_count(M.buf)
  for i = 1, total do
    if line_is_header(i) and header_is_expanded(i) then
      toggle_at_line(i)
    end
  end
end

function M.expand_week()
  if not M.buf then return end
  local focus = state.get_focus_day() or dateu.today()
  local function to_ts(s) return os.time({ year = tonumber(s:sub(1,4)), month = tonumber(s:sub(6,7)), day = tonumber(s:sub(9,10)), hour = 12 }) end
  local total = vim.api.nvim_buf_line_count(M.buf)
  for i = 1, total do
    if line_is_header(i) then
      local line = vim.api.nvim_buf_get_lines(M.buf, i - 1, i, false)[1]
      local dd, mm, yy = line:match('(%d%d)/(%d%d)/(%d%d)')
      if dd then
        local yyyy = tostring(2000 + tonumber(yy))
        local day = string.format('%s-%s-%s', yyyy, mm, dd)
        local diff = math.abs((to_ts(day) - to_ts(focus)) / (24*3600))
        if diff <= 3 and not header_is_expanded(i) then
          toggle_at_line(i)
        end
      end
    end
  end
end

function M.expand_range(start_day, end_day)
  if not M.buf then return end
  if not start_day or not end_day then return end
  local function to_ts(s) return os.time({ year = tonumber(s:sub(1,4)), month = tonumber(s:sub(6,7)), day = tonumber(s:sub(9,10)), hour = 12 }) end
  local st, en = to_ts(start_day), to_ts(end_day)
  if en < st then st, en = en, st end
  local total = vim.api.nvim_buf_line_count(M.buf)
  for i = 1, total do
    if line_is_header(i) then
      local line = vim.api.nvim_buf_get_lines(M.buf, i - 1, i, false)[1]
      local dd, mm, yy = line:match('(%d%d)/(%d%d)/(%d%d)')
      if dd then
        local yyyy = tostring(2000 + tonumber(yy))
        local day = string.format('%s-%s-%s', yyyy, mm, dd)
        local ts = to_ts(day)
        if ts >= st and ts <= en and not header_is_expanded(i) then
          toggle_at_line(i)
        end
      end
    end
  end
end

function M.rename_current()
  local item = current_item()
  if not item or not (item.type == 'task' or item.type == 'event' or item.type == 'note') then return end
  local line = vim.api.nvim_get_current_line()
  local current = line:gsub('^- %[[^%]]-%]%s*', ''):gsub('^- %s*[%[%]SA ]*%s*', ''):gsub('^%- %s*', '')
  vim.ui.input({ prompt = 'Rename label: ', default = current }, function(newlabel)
    if not newlabel or newlabel == '' then return end
    require('smartplanner.storage').update(item.id, { title = newlabel, label = newlabel })
    M.goto_date(item.date or (state.get_focus_day() or dateu.today()))
  end)
end

return M
