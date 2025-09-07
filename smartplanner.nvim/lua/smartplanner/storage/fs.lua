local config = require('smartplanner.config')
local json = require('smartplanner.util.json')
local fsu = require('smartplanner.util.fs')

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
function M.update(id, fields)
  vim.notify('fs.update stub for id=' .. tostring(id), vim.log.levels.DEBUG)
  return true
end

function M.delete(id)
  vim.notify('fs.delete stub for id=' .. tostring(id), vim.log.levels.DEBUG)
  return true
end

function M.move(id, fields)
  vim.notify('fs.move stub for id=' .. tostring(id), vim.log.levels.DEBUG)
  return true
end

function M.span(id, range)
  vim.notify('fs.span stub for id=' .. tostring(id), vim.log.levels.DEBUG)
  return true
end

function M.query_tasks(q)
  vim.notify('fs.query_tasks stub', vim.log.levels.DEBUG)
  return {}
end

function M.query_events(q)
  vim.notify('fs.query_events stub', vim.log.levels.DEBUG)
  return {}
end

function M.query_sprints(q)
  vim.notify('fs.query_sprints stub', vim.log.levels.DEBUG)
  return {}
end

return M
