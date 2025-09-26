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
local db = sqlite({ uri = db_path })

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
  -- defaults + instances
  local ts_start = tonumber(os.time({ year = tonumber(day:sub(1,4)), month = tonumber(day:sub(6,7)), day = tonumber(day:sub(9,10)), hour = 12 }))
  local rows = exec([[SELECT id,label,time_unit,delta_sec,start_ts,end_ts FROM delta_entries
                      WHERE (end_ts IS NULL OR end_ts >= :ts) AND start_ts <= :ts]], { ts = ts_start }) or {}
  local inst = exec([[SELECT di.*, de.label, de.time_unit FROM delta_instances di
                      JOIN delta_entries de ON de.id = di.delta_entry_id
                      WHERE di.day = :day]], { day = day }) or {}
  return rows, inst
end

-- Stubs for existing API to enable gradual migration; these can be filled next
function M.read_month() return { tasks = {}, events = {}, notes_index = {} } end
function M.write_month() return true end
function M.add_task() vim.notify('sqlite.add_task not yet implemented', vim.log.levels.WARN) end
function M.add_event() vim.notify('sqlite.add_event not yet implemented', vim.log.levels.WARN) end
function M.add_note() vim.notify('sqlite.add_note not yet implemented', vim.log.levels.WARN) end
function M.add_sprint() vim.notify('sqlite.add_sprint not yet implemented', vim.log.levels.WARN) end
function M.update() return false end
function M.delete() return false end
function M.move() return false end
function M.span() return false end
function M.query_tasks() return {} end
function M.query_events() return {} end
function M.query_sprints() return {} end

-- Quick inbox compatible helpers
function M.query_quick() return { quick_tasks = {}, quick_notes = {} } end
function M.add_quick_task() return false end
function M.add_quick_note() return false end
function M.update_quick() return false end
function M.delete_quick() return false end

return M
