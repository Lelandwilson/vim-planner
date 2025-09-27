-- SQLite backend (skeleton). Requires 'kkharji/sqlite.lua' plugin.
local ok, sqlite = pcall(require, 'sqlite')
if not ok then
  return setmetatable({}, {
    __index = function()
      return function()
        vim.notify('SmartPlanner: sqlite backend requires kkharji/sqlite.lua; falling back/unavailable', vim.log.levels.WARN)
        return nil
      end
    end
  })
end

local db_path = vim.fn.stdpath('data') .. '/smartplanner/smartplanner.db'
-- Ensure parent directory exists before opening
local db_dir = vim.fn.fnamemodify(db_path, ':h')
if vim.fn.isdirectory(db_dir) == 0 then
  vim.fn.mkdir(db_dir, 'p')
end
-- Open connection using sqlite.lua API
local db = (sqlite.open and sqlite.open(db_path)) or (sqlite.new and sqlite.new(db_path))

local M = {}

local function exec(sql, params)
  return db:eval(sql, params)
end

function M.init()
  exec([[PRAGMA journal_mode=WAL;]])
  exec([[CREATE TABLE IF NOT EXISTS items (
    id TEXT PRIMARY KEY,
    type TEXT,
    label TEXT,
    status TEXT,
    start_ts INTEGER,
    end_ts INTEGER,
    allday INTEGER,
    span INTEGER,
    duration_sec INTEGER,
    delta_sec INTEGER,
    estimate_sec INTEGER,
    actual_sec INTEGER,
    added_ts INTEGER,
    closed_ts INTEGER,
    day TEXT,
    week TEXT,
    month TEXT,
    calendar TEXT,
    priority INTEGER,
    order_index INTEGER,
    parent_id TEXT,
    sprint_id TEXT,
    body TEXT,
    tags TEXT,
    created_at TEXT,
    updated_at TEXT
  );]])
  exec([[CREATE INDEX IF NOT EXISTS idx_items_day_order ON items(day, order_index);]])
  exec([[CREATE INDEX IF NOT EXISTS idx_items_month ON items(month);]])
  exec([[CREATE INDEX IF NOT EXISTS idx_items_start ON items(start_ts);]])
  exec([[CREATE INDEX IF NOT EXISTS idx_items_end ON items(end_ts);]])
  exec([[CREATE INDEX IF NOT EXISTS idx_items_sprint ON items(sprint_id);]])

  exec([[CREATE TABLE IF NOT EXISTS sprints (
    id TEXT PRIMARY KEY,
    name TEXT,
    start_ts INTEGER,
    end_ts INTEGER,
    priority INTEGER,
    objective TEXT,
    color TEXT,
    created_at TEXT,
    updated_at TEXT
  );]])
  exec([[CREATE INDEX IF NOT EXISTS idx_sprints_start ON sprints(start_ts);]])
  exec([[CREATE INDEX IF NOT EXISTS idx_sprints_end ON sprints(end_ts);]])

  exec([[CREATE TABLE IF NOT EXISTS quick_inbox (
    id TEXT PRIMARY KEY,
    kind TEXT,
    label TEXT,
    status TEXT,
    created_at INTEGER
  );]])

  exec([[CREATE TABLE IF NOT EXISTS delta_entries (
    id TEXT PRIMARY KEY,
    label TEXT,
    time_unit TEXT,
    delta_sec INTEGER,
    start_ts INTEGER,
    end_ts INTEGER,
    created_at TEXT,
    updated_at TEXT
  );]])
  exec([[CREATE INDEX IF NOT EXISTS idx_delta_range ON delta_entries(start_ts, end_ts);]])

  exec([[CREATE TABLE IF NOT EXISTS delta_instances (
    id TEXT PRIMARY KEY,
    delta_entry_id TEXT,
    day TEXT,
    delta_sec INTEGER,
    note TEXT,
    created_at TEXT,
    updated_at TEXT
  );]])
  exec([[CREATE INDEX IF NOT EXISTS idx_delta_instances_day ON delta_instances(day);]])
end

-- Delta API
function M.add_delta_entry(e)
  e.id = e.id or require('smartplanner.util.id').uuid()
  exec([[INSERT INTO delta_entries(id,label,time_unit,delta_sec,start_ts,end_ts,created_at,updated_at)
         VALUES(:id,:label,:time_unit,:delta_sec,:start_ts,:end_ts,datetime('now'),datetime('now'))]], e)
  return e
end

function M.list_delta_entries()
  return exec([[SELECT * FROM delta_entries ORDER BY created_at DESC]]) or {}
end

function M.delete_delta_entry(id)
  exec([[DELETE FROM delta_instances WHERE delta_entry_id=:id]], { id = id })
  exec([[DELETE FROM delta_entries WHERE id=:id]], { id = id })
  return true
end

function M.add_delta_instance(inst)
  inst.id = inst.id or require('smartplanner.util.id').uuid()
  exec([[INSERT INTO delta_instances(id,delta_entry_id,day,delta_sec,note,created_at,updated_at)
         VALUES(:id,:delta_entry_id,:day,:delta_sec,:note,datetime('now'),datetime('now'))]], inst)
  return inst
end

function M.query_deltas_for_day(day)
  -- Only return per-day instances; delta_entries serve as templates
  local inst = exec([[SELECT di.*, de.label, de.time_unit FROM delta_instances di
                      JOIN delta_entries de ON de.id = di.delta_entry_id
                      WHERE di.day = :day]], { day = day }) or {}
  return {}, inst
end

function M.query_day(day)
  local t = exec([[SELECT * FROM items WHERE day = :d]], { d = day }) or {}
  local tasks, events, notes = {}, {}, {}
  for _, r in ipairs(t) do
    if r.type == 'task' then
      tasks[#tasks + 1] = { id = r.id, title = r.label, calendar = r.calendar, priority = r.priority, status = r.status, date = r.day, order_index = r.order_index, tags = {}, created_at = r.created_at, updated_at = r.updated_at }
    elseif r.type == 'event' then
      events[#events + 1] = { id = r.id, title = r.label, calendar = r.calendar, span = r.span == 1, start_date = r.start_ts and ymd(r.start_ts) or nil, end_date = r.end_ts and ymd(r.end_ts) or nil, date = r.day, priority = r.priority, order_index = r.order_index, allday = r.allday == 1 }
    elseif r.type == 'note' then
      notes[#notes + 1] = { id = r.id, date = r.day, path = r.label or ('note:' .. r.id), tags = {} }
    end
  end
  -- add spans intersecting the day
  local ts = os.time({ year = tonumber(day:sub(1,4)), month = tonumber(day:sub(6,7)), day = tonumber(day:sub(9,10)), hour = 12 })
  local span_rows = exec([[SELECT * FROM items WHERE type='event' AND span=1 AND NOT (end_ts < :ts OR start_ts > :ts)]], { ts = ts }) or {}
  for _, r in ipairs(span_rows) do
    events[#events + 1] = { id = r.id, title = r.label, calendar = r.calendar, span = true, start_date = r.start_ts and ymd(r.start_ts) or nil, end_date = r.end_ts and ymd(r.end_ts) or nil, priority = r.priority, order_index = r.order_index, allday = (r.allday == 1) }
  end
  return { tasks = tasks, events = events, notes = notes }
end

-- Stubs for existing API to enable gradual migration; these can be filled next
local function ymd(ts)
  local t = os.date('*t', ts)
  return string.format('%04d-%02d-%02d', t.year, t.month, t.day)
end

local function ymonth(ts)
  local t = os.date('*t', ts)
  return string.format('%04d-%02d', t.year, t.month)
end

local function compute_periods(day)
  local y, m, d = tonumber(day:sub(1,4)), tonumber(day:sub(6,7)), tonumber(day:sub(9,10))
  local ts = os.time({ year = y, month = m, day = d, hour = 12 })
  local week = os.date('%Y-W%V', ts)
  return week, string.format('%04d-%02d', y, m)
end

function M.read_month(year, month)
  local month_str = string.format('%04d-%02d', year, month)
  local rows = exec([[SELECT * FROM items WHERE month = :m]], { m = month_str }) or {}
  local tasks, events, notes_index = {}, {}, {}
  for _, r in ipairs(rows) do
    if r.type == 'task' then
      table.insert(tasks, { id = r.id, title = r.label, calendar = r.calendar, priority = r.priority, status = r.status, date = r.day, order_index = r.order_index, tags = {}, created_at = r.created_at, updated_at = r.updated_at })
    elseif r.type == 'event' then
      table.insert(events, { id = r.id, title = r.label, calendar = r.calendar, span = r.span == 1, start_date = r.start_ts and ymd(r.start_ts) or nil, end_date = r.end_ts and ymd(r.end_ts) or nil, date = r.day, priority = r.priority, order_index = r.order_index, start_ts = r.start_ts, end_ts = r.end_ts, allday = r.allday == 1 })
    elseif r.type == 'note' then
      table.insert(notes_index, { id = r.id, date = r.day, path = r.label or ('note:' .. r.id), tags = {} })
    end
  end
  return { month = month_str, tasks = tasks, events = events, notes_index = notes_index }
end

function M.write_month() return true end

local function upsert_item(r)
  exec([[INSERT INTO items(id,type,label,status,start_ts,end_ts,allday,span,duration_sec,delta_sec,estimate_sec,actual_sec,added_ts,closed_ts,day,week,month,calendar,priority,order_index,parent_id,sprint_id,body,tags,created_at,updated_at)
         VALUES(:id,:type,:label,:status,:start_ts,:end_ts,:allday,:span,:duration_sec,:delta_sec,:estimate_sec,:actual_sec,:added_ts,:closed_ts,:day,:week,:month,:calendar,:priority,:order_index,:parent_id,:sprint_id,:body,:tags,datetime('now'),datetime('now'))
         ON CONFLICT(id) DO UPDATE SET
           label=excluded.label,status=excluded.status,start_ts=excluded.start_ts,end_ts=excluded.end_ts,allday=excluded.allday,span=excluded.span,duration_sec=excluded.duration_sec,delta_sec=excluded.delta_sec,estimate_sec=excluded.estimate_sec,actual_sec=excluded.actual_sec,day=excluded.day,week=excluded.week,month=excluded.month,calendar=excluded.calendar,priority=excluded.priority,order_index=excluded.order_index,parent_id=excluded.parent_id,sprint_id=excluded.sprint_id,body=excluded.body,tags=excluded.tags,updated_at=datetime('now')
  ]], r)
end

local function ensure_periods(rec)
  if rec.day and (not rec.month or not rec.week) then
    rec.week, rec.month = compute_periods(rec.day)
  elseif rec.start_ts and (not rec.day) then
    rec.day = ymd(rec.start_ts)
    rec.week, rec.month = compute_periods(rec.day)
  end
end

function M.add_task(t)
  local rec = {
    id = t.id or require('smartplanner.util.id').uuid(),
    type = 'task',
    label = t.title or t.label or '',
    status = t.status or 'todo',
    start_ts = nil,
    end_ts = nil,
    allday = 0,
    span = 0,
    duration_sec = nil,
    delta_sec = nil,
    estimate_sec = t.estimate and (t.estimate * 60) or nil,
    actual_sec = t.actual and (t.actual * 60) or nil,
    added_ts = os.time(),
    closed_ts = nil,
    day = t.date,
    calendar = t.calendar,
    priority = t.priority,
    order_index = t.order_index or 0,
    parent_id = t.parent_id,
    sprint_id = t.sprint_id,
    body = t.notes,
    tags = t.tags and table.concat(t.tags, ',') or nil,
  }
  ensure_periods(rec)
  upsert_item(rec)
  return rec
end

function M.add_event(e)
  local rec = {
    id = e.id or require('smartplanner.util.id').uuid(),
    type = 'event',
    label = e.title or e.label or '',
    status = e.status or 'none',
    start_ts = e.start_ts,
    end_ts = e.end_ts,
    allday = (e.allday and 1 or 0),
    span = (e.span and 1 or 0),
    priority = e.priority,
    order_index = e.order_index or 0,
    calendar = e.calendar,
  }
  if e.date then
    rec.day = e.date
  else
    if (not rec.start_ts) and e.start_date then rec.start_ts = os.time({ year = tonumber(e.start_date:sub(1,4)), month = tonumber(e.start_date:sub(6,7)), day = tonumber(e.start_date:sub(9,10)), hour = 12 }) end
    if (not rec.end_ts) and e.end_date then rec.end_ts = os.time({ year = tonumber(e.end_date:sub(1,4)), month = tonumber(e.end_date:sub(6,7)), day = tonumber(e.end_date:sub(9,10)), hour = 12 }) end
  end
  ensure_periods(rec)
  upsert_item(rec)
  return rec
end

function M.add_note(n)
  local rec = {
    id = n.id or require('smartplanner.util.id').uuid(),
    type = 'note',
    label = n.title or n.label or '',
    status = 'none',
    day = n.date,
    body = n.body or '',
    calendar = n.calendar,
  }
  ensure_periods(rec)
  upsert_item(rec)
  return rec
end

function M.add_sprint(sp)
  sp.id = sp.id or require('smartplanner.util.id').uuid()
  local st = os.time({ year = tonumber(sp.start_date:sub(1,4)), month = tonumber(sp.start_date:sub(6,7)), day = tonumber(sp.start_date:sub(9,10)), hour = 12 })
  local en = os.time({ year = tonumber(sp.end_date:sub(1,4)), month = tonumber(sp.end_date:sub(6,7)), day = tonumber(sp.end_date:sub(9,10)), hour = 12 })
  exec([[INSERT INTO sprints(id,name,start_ts,end_ts,priority,objective,color,created_at,updated_at)
         VALUES(:id,:name,:st,:en,:priority,:objective,:color,datetime('now'),datetime('now'))
         ON CONFLICT(id) DO UPDATE SET name=excluded.name,start_ts=excluded.start_ts,end_ts=excluded.end_ts,priority=excluded.priority,objective=excluded.objective,color=excluded.color,updated_at=datetime('now')
  ]], { id = sp.id, name = sp.name, st = st, en = en, priority = sp.priority or 0, objective = sp.objective, color = sp.color })
  return sp
end

function M.update(id, fields)
  -- naive: fetch then upsert
  local row = (exec([[SELECT * FROM items WHERE id=:id]], { id = id }) or {})[1]
  if not row then return false end
  for k, v in pairs(fields) do
    if k == 'title' then row.label = v
    elseif k == 'date' then row.day = v
    elseif k == 'status' then row.status = v
    elseif k == 'priority' then row.priority = v
    elseif k == 'order_index' then row.order_index = v
    elseif k == 'start_date' then row.start_ts = os.time({ year = tonumber(v:sub(1,4)), month = tonumber(v:sub(6,7)), day = tonumber(v:sub(9,10)), hour = 12 })
    elseif k == 'end_date' then row.end_ts = os.time({ year = tonumber(v:sub(1,4)), month = tonumber(v:sub(6,7)), day = tonumber(v:sub(9,10)), hour = 12 })
    else row[k] = v end
  end
  ensure_periods(row)
  upsert_item(row)
  return true
end

function M.delete(id)
  exec([[DELETE FROM items WHERE id=:id]], { id = id })
  return true
end

function M.move(id, fields)
  return M.update(id, fields)
end

function M.span(id, range)
  return M.update(id, { span = 1, start_date = range.start_date, end_date = range.end_date })
end

function M.query_tasks(q)
  local start = q.range and q.range.start or ymd(os.time())
  local finish = q.range and q.range['end'] or start
  return exec([[SELECT * FROM items WHERE type='task' AND day BETWEEN :s AND :e]], { s = start, e = finish }) or {}
end

function M.query_events(q)
  local start = q.range and q.range.start or ymd(os.time())
  local finish = q.range and q.range['end'] or start
  return exec([[SELECT * FROM items WHERE type='event' AND (
                 (day BETWEEN :s AND :e) OR
                 (span = 1 AND NOT (end_ts < strftime('%s', :s) OR start_ts > strftime('%s', :e)))
               )]], { s = start, e = finish }) or {}
end

function M.query_sprints(q)
  local start = q.range and q.range.start or ymd(os.time())
  local finish = q.range and q.range['end'] or start
  local st = os.time({ year = tonumber(start:sub(1,4)), month = tonumber(start:sub(6,7)), day = tonumber(start:sub(9,10)), hour = 12 })
  local en = os.time({ year = tonumber(finish:sub(1,4)), month = tonumber(finish:sub(6,7)), day = tonumber(finish:sub(9,10)), hour = 12 })
  return exec([[SELECT * FROM sprints WHERE NOT (end_ts < :st OR start_ts > :en)]], { st = st, en = en }) or {}
end

-- Quick inbox compatible helpers
function M.query_quick() return { quick_tasks = {}, quick_notes = {} } end
function M.add_quick_task() return false end
function M.add_quick_note() return false end
function M.update_quick() return false end
function M.delete_quick() return false end

-- Migration from FS shards to SQLite
function M.migrate_from_fs()
  local fs = require('smartplanner.storage.fs')
  -- naive: import current year and neighbors
  local y = tonumber(os.date('%Y'))
  for year = y - 1, y + 1 do
    for m = 1, 12 do
      local month = fs.read_month(year, m)
      if month and ((month.tasks and #month.tasks > 0) or (month.events and #month.events > 0) or (month.notes_index and #month.notes_index > 0)) then
        for _, t in ipairs(month.tasks or {}) do M.add_task({ id = t.id, title = t.title, date = t.date, status = t.status, priority = t.priority, order_index = t.order_index, calendar = t.calendar, tags = t.tags }) end
        for _, e in ipairs(month.events or {}) do
          if e.span then M.add_event({ id = e.id, title = e.title, span = true, start_date = e.start_date, end_date = e.end_date, priority = e.priority, order_index = e.order_index, calendar = e.calendar })
          else M.add_event({ id = e.id, title = e.title, date = e.date, allday = e.allday, priority = e.priority, order_index = e.order_index, calendar = e.calendar }) end
        end
        for _, n in ipairs(month.notes_index or {}) do M.add_note({ id = n.id, title = n.title or n.path, date = n.date, body = '' }) end
      end
    end
    -- sprints
    for _, sp in ipairs(fs.query_sprints({ range = { start = string.format('%04d-01-01', year), ['end'] = string.format('%04d-12-31', year) } }) or {}) do
      M.add_sprint(sp)
    end
  end
  vim.notify('SmartPlanner: Migration fs->sqlite complete', vim.log.levels.INFO)
end

return M
