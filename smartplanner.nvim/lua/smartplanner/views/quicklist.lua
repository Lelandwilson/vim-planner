-- Quick Notes / Mini Todo List (floating)
local idu = require('smartplanner.util.id')
local store = require('smartplanner.storage.fs')
local dateu = require('smartplanner.util.date')

local M = { win = nil, buf = nil, index = {}, current_date = nil }

local function render_day_section(lines, date)
  local y, m = dateu.year_month(date)
  local month = store.read_month(y, m)
  lines[#lines + 1] = '## ' .. date .. ' — Day View'
  local events = {}
  for _, e in ipairs(month.events or {}) do
    if (e.date == date) or (e.span and dateu.range_intersect(e.start_date, e.end_date, date, date)) then
      events[#events + 1] = e
    end
  end
  if #events > 0 then
    lines[#lines + 1] = '### Events'
    for _, e in ipairs(events) do lines[#lines + 1] = '- ' .. (e.title or e.id) end
    lines[#lines + 1] = ''
  end
  local tasks = {}
  for _, t in ipairs(month.tasks or {}) do if t.date == date then tasks[#tasks + 1] = t end end
  if #tasks > 0 then
    lines[#lines + 1] = '### Tasks'
    for _, t in ipairs(tasks) do
      local token = (t.status == 'done') and '[✓]' or '[ ]'
      lines[#lines + 1] = '- ' .. token .. ' ' .. (t.title or t.id)
    end
    lines[#lines + 1] = ''
  end
  local notes = {}
  for _, n in ipairs(month.notes_index or {}) do if n.date == date then notes[#notes + 1] = n end end
  if #notes > 0 then
    lines[#lines + 1] = '### Notes'
    for _, n in ipairs(notes) do lines[#lines + 1] = '- ' .. (n.title or n.path) end
    lines[#lines + 1] = ''
  end
end

local function render()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    M.buf = vim.api.nvim_create_buf(false, true)
  end
  local y = tonumber(os.date('%Y'))
  local inbox = store.query_quick(y)
  local lines = { '# Quick Notes & Todos (' .. y .. ')', '' }
  lines[#lines + 1] = '_Keys: a add todo • n note • x toggle • p promote • D delete • ]d/[d next/prev day • g goto date • c clear date_'
  lines[#lines + 1] = ''
  M.index = {}
  lines[#lines + 1] = '## Todos'
  for _, t in ipairs(inbox.quick_tasks or {}) do
    local token = (t.status == 'done') and '[✓]' or '[ ]'
    lines[#lines + 1] = string.format('- %s %s', token, t.title or '')
    M.index[#lines] = { kind = 'task', id = t.id }
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '## Notes'
  for _, n in ipairs(inbox.quick_notes or {}) do
    lines[#lines + 1] = string.format('- %s', (n.title or n.body or ''))
    M.index[#lines] = { kind = 'note', id = n.id }
  end
  if M.current_date then
    lines[#lines + 1] = ''
    render_day_section(lines, M.current_date)
  end
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
end

local function open_float()
  if M.win and vim.api.nvim_win_is_valid(M.win) then return end
  render()
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.5)
  local height = math.floor(ui.height * 0.6)
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  M.win = vim.api.nvim_open_win(M.buf, true, {
    relative = 'editor', width = width, height = height, row = row, col = col,
    border = 'rounded', style = 'minimal', zindex = 60,
  })
  vim.keymap.set('n', '<C-c>', function() M.close() end, { buffer = M.buf, nowait = true })
  vim.keymap.set('n', 'q', function() M.close() end, { buffer = M.buf, nowait = true })
  -- actions
  vim.keymap.set('n', 'a', function()
    vim.ui.input({ prompt = 'Quick todo: ' }, function(val)
      if not val or val == '' then return end
      store.add_quick_task({ id = idu.uuid(), title = val, status = 'todo', created_at = dateu.today() })
      render()
    end)
  end, { buffer = M.buf, desc = 'Add quick todo' })
  vim.keymap.set('n', 'n', function()
    vim.ui.input({ prompt = 'Quick note: ' }, function(val)
      if not val or val == '' then return end
      store.add_quick_note({ id = idu.uuid(), title = val, created_at = dateu.today() })
      render()
    end)
  end, { buffer = M.buf, desc = 'Add quick note' })
  vim.keymap.set('n', 'x', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local entry = M.index[lnum]
    if not entry or entry.kind ~= 'task' then return end
    -- detect current done state from line, toggle
    local line = vim.api.nvim_buf_get_lines(M.buf, lnum - 1, lnum, false)[1]
    local done = line:match('%[✓%]') ~= nil
    store.update_quick(entry.id, { status = done and 'todo' or 'done' })
    render()
  end, { buffer = M.buf, desc = 'Toggle quick todo' })
  vim.keymap.set('n', 'p', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local entry = M.index[lnum]
    if not entry or entry.kind ~= 'task' then return end
    vim.ui.input({ prompt = 'Promote to date (YYYY-MM-DD): ', default = dateu.today() }, function(d)
      if not d or d == '' then return end
      store.promote_quick_to_task(entry.id, d)
      render()
    end)
  end, { buffer = M.buf, desc = 'Promote quick todo to dated task' })
  vim.keymap.set('n', 'D', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local entry = M.index[lnum]
    if not entry then return end
    store.delete_quick(entry.id)
    render()
  end, { buffer = M.buf, desc = 'Delete quick item' })
  -- Day navigation and date filter
  vim.keymap.set('n', ']d', function()
    M.current_date = M.current_date or dateu.today()
    M.current_date = dateu.add_days(M.current_date, 1)
    render()
  end, { buffer = M.buf, desc = 'Next day (day view)' })
  vim.keymap.set('n', '[d', function()
    M.current_date = M.current_date or dateu.today()
    M.current_date = dateu.add_days(M.current_date, -1)
    render()
  end, { buffer = M.buf, desc = 'Prev day (day view)' })
  vim.keymap.set('n', 'g', function()
    vim.ui.input({ prompt = 'Go to date (YYYY-MM-DD): ', default = dateu.today() }, function(d)
      if not d or d == '' then return end
      M.current_date = d
      render()
    end)
  end, { buffer = M.buf, desc = 'Goto date (day view)' })
  vim.keymap.set('n', 'c', function()
    M.current_date = nil
    render()
  end, { buffer = M.buf, desc = 'Clear date (inbox only)' })
end

function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then return M.close() end
  open_float()
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_close(M.win, true) end
  M.win, M.buf = nil, nil
end

return M
