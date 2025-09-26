local config = require('smartplanner.config')
local state = require('smartplanner.state')
local keymaps = require('smartplanner.ui.keymaps')
local highlight = require('smartplanner.ui.highlight')
local planner_view = require('smartplanner.views.planner')
local calendar_view = require('smartplanner.views.calendar')
local mini_view = require('smartplanner.views.mini')
local planner_float = require('smartplanner.views.planner_float')
local quicklist = require('smartplanner.views.quicklist')
local export_md = require('smartplanner.export.md')
local export_csv = require('smartplanner.export.csv')
local storage = require('smartplanner.storage')

local M = {}

-- Setup per §4 Config API. Merges user opts, registers commands/keymaps.
function M.setup(opts)
  local cfg = config.setup(opts or {})
  state.set_config(cfg)
  if cfg.telescope and cfg.telescope.enable then
    pcall(function()
      require('smartplanner.ui.telescope').setup()
    end)
  end
  pcall(highlight.setup)
  if cfg.keymaps == 'default' then
    keymaps.apply_defaults()
  elseif type(cfg.keymaps) == 'table' then
    keymaps.apply_custom(cfg.keymaps)
  end
  if type(storage.init) == 'function' then pcall(storage.init) end
  M._register_commands()
end

-- Public Lua API (§9)
function M.open_planner(opts)
  return planner_view.open(opts or {})
end

function M.open_calendar(opts)
  return calendar_view.open(opts or { view = 'month' })
end

function M.toggle_mini(opts)
  return mini_view.toggle(opts or {})
end

function M.toggle_quicklist()
  return quicklist.toggle()
end

function M.capture(payload)
  return require('smartplanner.ui.modal').capture(payload or {})
end

function M.update(id, fields)
  return require('smartplanner.storage').update(id, fields)
end

function M.delete(id)
  return require('smartplanner.storage').delete(id)
end

function M.move(id, fields)
  return require('smartplanner.storage').move(id, fields)
end

function M.span(id, range)
  return require('smartplanner.storage').span(id, range)
end

M.query = {
  tasks = function(q) return require('smartplanner.storage').query_tasks(q or {}) end,
  events = function(q) return require('smartplanner.storage').query_events(q or {}) end,
  sprints = function(q) return require('smartplanner.storage').query_sprints(q or {}) end,
}

function M.export(opts)
  opts = opts or { fmt = 'md', scope = 'week' }
  if opts.fmt == 'csv' then
    return export_csv.export(opts)
  else
    return export_md.export(opts)
  end
end

function M.import(opts)
  vim.notify('SmartPlanner import not implemented (stub)', vim.log.levels.WARN)
end

-- User commands (§5.1). Minimal stubs delegate to API above.
function M._register_commands()
  local create = vim.api.nvim_create_user_command

  create('SmartPlannerOpen', function(cmd)
    local args = cmd.fargs
    local view = args[1] or 'planner'
    if view == 'planner' then
      M.open_planner({ date = args[2] })
    elseif view == 'calendar' then
      local mode = args[2] or 'month'
      local date = args[3]
      M.open_calendar({ date = date, view = mode })
    elseif view == 'mini' then
      M.toggle_mini({ date = args[2] })
    elseif view == 'planner_float' then
      planner_float.open({ date = args[2] })
    elseif view == 'quick' or view == 'quicklist' then
      quicklist.toggle()
    else
      vim.notify('Unknown view: ' .. view, vim.log.levels.ERROR)
    end
  end, { nargs = '*', complete = function(_, _)
    return { 'planner', 'calendar', 'mini', 'planner_float', 'quick', 'quicklist', 'month', 'week', 'day' }
  end })

  create('SmartPlannerCapture', function(cmd)
    local typearg = cmd.fargs[1]
    require('smartplanner.ui.modal').capture({ type = typearg })
  end, { nargs = '*', complete = function()
    return { 'task', 'event', 'note', 'sprint' }
  end })

  create('SmartPlannerGoto', function(cmd)
    local arg = cmd.fargs[1] or 'today'
    planner_view.goto_date(arg)
  end, { nargs = '?' })

  create('SmartPlannerSearch', function(cmd)
    local which = cmd.fargs[1] or 'tasks'
    require('smartplanner.ui.telescope').open_picker(which)
  end, { nargs = '?' })

  create('SmartPlannerExport', function(cmd)
    local fmt = cmd.fargs[1] or 'md'
    local scope = cmd.fargs[2] or 'month' -- day|week|month
    local date = cmd.fargs[3]
    M.export({ fmt = fmt, scope = scope, date = date })
  end, { nargs = '*', complete = function(_, _)
    return { 'md', 'csv', 'day', 'week', 'month' }
  end })

  create('SmartPlannerConfig', function()
    require('smartplanner.config').open_help()
  end, {})

  create('SmartPlannerSync', function()
    require('smartplanner.views.mini').sync_focus()
  end, {})

  create('SmartPlannerMigrate', function(cmd)
    local dir = (cmd.fargs[1] or 'fs->sqlite')
    if dir ~= 'fs->sqlite' then
      vim.notify('Usage: :SmartPlannerMigrate fs->sqlite', vim.log.levels.WARN)
      return
    end
    local st = require('smartplanner.storage')
    if type(st.migrate_from_fs) == 'function' then
      st.migrate_from_fs()
    else
      vim.notify('Storage backend does not support migration', vim.log.levels.ERROR)
    end
  end, { nargs = '?' })
end

return M
