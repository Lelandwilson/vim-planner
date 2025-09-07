-- Calendar view (§2.2 Calendar View) — Month grid
local state = require('smartplanner.state')
local dateu = require('smartplanner.util.date')
local store = require('smartplanner.storage.fs')

local hl = require('smartplanner.ui.highlight')
local M = { buf = nil }

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

local function header_line(y, m)
  local month_name = os.date('%B %Y', os.time({ year = y, month = m, day = 1 }))
  return '# ' .. month_name
end

local function collect_for_month(y, m)
  local month_tbl = store.read_month(y, m)
  -- load sprints
  local s_raw = (function()
    local ok, tbl = pcall(function()
      local root = (require('smartplanner.config').get().year_root):gsub('%%Y', tostring(y))
      local data = require('smartplanner.util.fs').read_file(root .. '/sprints.json')
      return data and (require('smartplanner.util.json').decode(data) or { sprints = {} }) or { sprints = {} }
    end)
    if ok then return tbl else return { sprints = {} } end
  end)()
  return month_tbl, (s_raw.sprints or {})
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
      singles[#singles + 1] = 'E:' .. (e.title or e.id)
    end
  end
  for _, t in ipairs(month_tbl.tasks or {}) do if t.date == day then singles[#singles + 1] = 'T:' .. t.title end end
  for _, n in ipairs(month_tbl.notes_index or {}) do if n.date == day then singles[#singles + 1] = 'N:' .. (n.title or n.path) end end
  return spans, singles
end

local function render_month_grid(buf, date)
  local y, m = dateu.year_month(date)
  local grid = dateu.month_grid(y, m)
  local month_tbl, sprints = collect_for_month(y, m)
  local lines = { header_line(y, m), '' }
  lines[#lines + 1] = 'Mon   Tue   Wed   Thu   Fri   Sat   Sun'
  lines[#lines + 1] = ('-'):rep(60)
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
end

local function render_day_view(buf, date)
  local y, m = dateu.year_month(date)
  local month_tbl, sprints = collect_for_month(y, m)
  local lines = { '# Day — ' .. date, '' }
  local spans, singles = cell_summary(date, month_tbl, sprints)
  if #spans > 0 then
    lines[#lines + 1] = 'Top band (spans):'
    for _, s in ipairs(spans) do lines[#lines + 1] = '- ' .. s end
    lines[#lines + 1] = ''
  end
  if #singles > 0 then
    lines[#lines + 1] = 'Items:'
    for _, s in ipairs(singles) do lines[#lines + 1] = '- ' .. s end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  hl.hl_line(buf, 0, 'SmartPlannerHeader')
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
  return buf
end

return M
