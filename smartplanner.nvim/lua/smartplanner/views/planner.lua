-- Planner view (§2.2 Planner View)
local state = require('smartplanner.state')
local dateu = require('smartplanner.util.date')
local store = require('smartplanner.storage.fs')

local M = { buf = nil, line_index = {} }

local function ensure_buf(title)
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    vim.cmd('tabnew')
    M.buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(M.buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
    vim.api.nvim_buf_set_name(M.buf, 'SmartPlanner: ' .. title)
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
  lines[#lines + 1] = string.format('## %s', day)
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
  local month_tbl = store.read_month(y, m)
  local days = dateu.month_days(y, m)
  local sprints = load_sprints(y)
  M.line_index = {}
  local lines = { string.format('# Planner — %04d-%02d', y, m), '' }
  for _, d in ipairs(days) do render_day(lines, d, month_tbl, sprints) end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function M.open(opts)
  local buf = ensure_buf('Planner')
  local day = opts.date or dateu.today()
  state.set_focus_day(day)
  render_month(buf, day)
  -- Sync mini on scroll/cursor
  vim.api.nvim_create_autocmd({ 'WinScrolled', 'CursorMoved' }, {
    buffer = buf,
    callback = function()
      state.set_focus_day(day)
      local ok, mini = pcall(require, 'smartplanner.views.mini')
      if ok then mini.sync_focus() end
    end,
  })
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
  local now = require('smartplanner.storage.fs')
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
    require('smartplanner.storage.fs').move(item.id, { date = val, start_date = val })
    M.goto_date(val)
  end)
end

function M.move_up()
  local item = current_item()
  if not item or item.type ~= 'task' then return end
  require('smartplanner.storage.fs').reorder_task(item.date, item.id, 'up')
  M.goto_date(item.date)
end

function M.move_down()
  local item = current_item()
  if not item or item.type ~= 'task' then return end
  require('smartplanner.storage.fs').reorder_task(item.date, item.id, 'down')
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

return M
