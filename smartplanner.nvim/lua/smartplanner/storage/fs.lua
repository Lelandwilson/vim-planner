local config = require('smartplanner.config')
local json = require('smartplanner.util.json')
local fsu = require('smartplanner.util.fs')
local dateu = require('smartplanner.util.date')

local M = {}

-- Resolve year root with %Y expansion (§4 notes)
local function year_root(opts)
  local cfg = config.get()
  local y = (opts and opts.year) or os.date('%Y')
  return (cfg.year_root or (vim.fn.stdpath('data') .. '/smartplanner/%Y')):gsub('%%Y', y)
end

local function month_shard_path(year, month)
  local root = year_root({ year = year })
  return string.format('%s/months/%04d-%02d.json', root, year, month)
end

function M.read_month(year, month)
  local p = month_shard_path(year, month)
  local data = fsu.read_file(p)
  if not data then
    return { month = string.format('%04d-%02d', year, month), tasks = {}, events = {}, notes_index = {} }
  end
  return json.decode(data) or { month = string.format('%04d-%02d', year, month), tasks = {}, events = {}, notes_index = {} }
end

function M.write_month(year, month, tbl)
  local p = month_shard_path(year, month)
  fsu.mkdirp(vim.fn.fnamemodify(p, ':h'))
  fsu.write_file(p, json.encode(tbl))
  return true
end

-- CRUD stubs for API (§9). Real implementations will locate the shard and mutate.
local function load_year_file(year, name, default)
  local root = year_root({ year = year })
  local path = string.format('%s/%s', root, name)
  local data = fsu.read_file(path)
  if not data then return default, path end
  return (json.decode(data) or default), path
end

local function save_year_file(year, name, tbl)
  local root = year_root({ year = year })
  local path = string.format('%s/%s', root, name)
  fsu.mkdirp(vim.fn.fnamemodify(path, ':h'))
  fsu.write_file(path, json.encode(tbl))
  return true
end

-- Sprints are stored at year root (§3.1)
local function read_sprints(year)
  local s, path = load_year_file(year, 'sprints.json', { sprints = {} })
  return s, path
end

local function write_sprints(year, tbl)
  return save_year_file(year, 'sprints.json', tbl)
end

local function upsert_in(list, id, obj)
  for i, it in ipairs(list) do
    if it.id == id then list[i] = vim.tbl_extend('force', it, obj); return true end
  end
  list[#list + 1] = obj
  return true
end

local function remove_from(list, id)
  for i, it in ipairs(list) do
    if it.id == id then table.remove(list, i); return true end
  end
  return false
end

local function find_item(month_tbl, id)
  for _, key in ipairs({ 'tasks', 'events', 'notes_index' }) do
    for i, it in ipairs(month_tbl[key] or {}) do
      if it.id == id then return key, i, it end
    end
  end
  return nil
end

local function month_for_date(date_str)
  local y, m = dateu.year_month(date_str)
  return y, m
end

function M.add_task(task)
  local y, m = month_for_date(task.date)
  local month = M.read_month(y, m)
  month.tasks = month.tasks or {}
  month.tasks[#month.tasks + 1] = task
  M.write_month(y, m, month)
  return task
end

function M.add_event(event)
  local y, m
  if event.start_date then y, m = month_for_date(event.start_date) else y, m = month_for_date(event.date) end
  local month = M.read_month(y, m)
  month.events = month.events or {}
  month.events[#month.events + 1] = event
  M.write_month(y, m, month)
  return event
end

function M.add_note(note)
  -- write note markdown with front matter (§3.1)
  local y, m = month_for_date(note.date)
  local root = year_root({ year = y })
  local notes_dir = string.format('%s/notes', root)
  fsu.mkdirp(notes_dir)
  local slug = note.title and note.title:lower():gsub('[^a-z0-9]+', '-') or 'note'
  local path = string.format('%s/%s-%02d-%02d-%s.md', notes_dir, tostring(y), m, tonumber(note.date:sub(9,10)), slug)
  local fm = {
    '---',
    'id: ' .. note.id,
    'calendar: ' .. (note.calendar or 'Work'),
    'date: ' .. note.date,
    'tags: [' .. table.concat(note.tags or {}, ',') .. ']',
    'links: []',
    '---', '',
    note.body or '',
  }
  fsu.write_file(path, table.concat(fm, '\n'))
  -- index in month
  local month = M.read_month(y, m)
  month.notes_index = month.notes_index or {}
  month.notes_index[#month.notes_index + 1] = { id = note.id, date = note.date, path = string.format('notes/%s', vim.fn.fnamemodify(path, ':t')), tags = note.tags or {} }
  M.write_month(y, m, month)
  return note
end

function M.add_sprint(sprint)
  local y = tonumber(sprint.start_date:sub(1,4))
  local s, _ = read_sprints(y)
  s.sprints = s.sprints or {}
  s.sprints[#s.sprints + 1] = sprint
  write_sprints(y, s)
  return sprint
end

function M.update(id, fields)
  -- try all months in current and adjacent months (simple approach)
  local now = os.date('*t')
  for dy = -1, 1 do
    local y = now.year + dy
    for m = 1, 12 do
      local month = M.read_month(y, m)
      local key, idx, item = find_item(month, id)
      if key then
        month[key][idx] = vim.tbl_extend('force', item, fields)
        M.write_month(y, m, month)
        return true
      end
    end
  end
  -- sprints
  local s, path_year = read_sprints(now.year)
  if s and s.sprints then
    for i, it in ipairs(s.sprints) do
      if it.id == id then s.sprints[i] = vim.tbl_extend('force', it, fields); write_sprints(now.year, s); return true end
    end
  end
  return false
end

function M.delete(id)
  local now = os.date('*t')
  for y = now.year - 1, now.year + 1 do
    for m = 1, 12 do
      local month = M.read_month(y, m)
      local key, idx = find_item(month, id)
      if key then
        table.remove(month[key], idx)
        M.write_month(y, m, month)
        return true
      end
    end
    local s = read_sprints(y)
    s = s and s or { sprints = {} }
  end
  return false
end

function M.move(id, fields)
  -- move between dates (tasks/events)
  local now = os.date('*t')
  for y = now.year - 1, now.year + 1 do
    for m = 1, 12 do
      local month = M.read_month(y, m)
      local key, idx, item = find_item(month, id)
      if key and (key == 'tasks' or key == 'events') then
        table.remove(month[key], idx)
        M.write_month(y, m, month)
        local new_item = vim.tbl_extend('force', item, fields)
        if key == 'tasks' then return M.add_task(new_item) end
        if key == 'events' then return M.add_event(new_item) end
      end
    end
  end
  return false
end

function M.span(id, range)
  return M.update(id, { span = true, start_date = range.start_date, end_date = range.end_date })
end

local function within(date, start_date, end_date)
  return start_date <= date and date <= end_date
end

function M.query_tasks(q)
  local res = {}
  local y1, m1 = dateu.year_month(q.range and q.range.start or dateu.today())
  local y2, m2 = dateu.year_month(q.range and q.range['end'] or dateu.today())
  for y = y1, y2 do
    for m = 1, 12 do
      if (y > y1 or m >= m1) and (y < y2 or m <= m2) then
        local month = M.read_month(y, m)
        for _, t in ipairs(month.tasks or {}) do
          if not q.status or t.status == q.status then
            res[#res + 1] = t
          end
        end
      end
    end
  end
  return res
end

function M.query_events(q)
  local res = {}
  local y1, m1 = dateu.year_month(q.range and q.range.start or dateu.today())
  local y2, m2 = dateu.year_month(q.range and q.range['end'] or dateu.today())
  for y = y1, y2 do
    for m = 1, 12 do
      if (y > y1 or m >= m1) and (y < y2 or m <= m2) then
        local month = M.read_month(y, m)
        for _, e in ipairs(month.events or {}) do
          res[#res + 1] = e
        end
      end
    end
  end
  return res
end

function M.query_sprints(q)
  local res = {}
  local y1 = tonumber((q.range and q.range.start or dateu.today()):sub(1,4))
  local y2 = tonumber((q.range and q.range['end'] or dateu.today()):sub(1,4))
  for y = y1, y2 do
    local s = read_sprints(y)
    s = (type(s) == 'table' and s.sprints) and s or (s and s.sprints) or {}
    for _, sp in ipairs(s or {}) do res[#res + 1] = sp end
  end
  return res
end

return M
