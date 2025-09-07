local config = require('smartplanner.config')
local state = require('smartplanner.state')
local keymaps = require('smartplanner.ui.keymaps')
local planner_view = require('smartplanner.views.planner')
local calendar_view = require('smartplanner.views.calendar')
local mini_view = require('smartplanner.views.mini')
local export_md = require('smartplanner.export.md')
local export_csv = require('smartplanner.export.csv')

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
  if cfg.keymaps == 'default' then
    keymaps.apply_defaults()
  elseif type(cfg.keymaps) == 'table' then
    keymaps.apply_custom(cfg.keymaps)
  end
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

function M.capture(payload)
  return require('smartplanner.ui.modal').capture(payload or {})
end

function M.update(id, fields)
  return require('smartplanner.storage.fs').update(id, fields)
end

function M.delete(id)
  return require('smartplanner.storage.fs').delete(id)
end

function M.move(id, fields)
  return require('smartplanner.storage.fs').move(id, fields)
end

function M.span(id, range)
  return require('smartplanner.storage.fs').span(id, range)
end

M.query = {
  tasks = function(q) return require('smartplanner.storage.fs').query_tasks(q or {}) end,
  events = function(q) return require('smartplanner.storage.fs').query_events(q or {}) end,
  sprints = function(q) return require('smartplanner.storage.fs').query_sprints(q or {}) end,
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
      M.open_calendar({ date = args[2], view = 'month' })
    elseif view == 'mini' then
      M.toggle_mini({ date = args[2] })
    else
      vim.notify('Unknown view: ' .. view, vim.log.levels.ERROR)
    end
  end, { nargs = '*', complete = function(_, _)
    return { 'planner', 'calendar', 'mini' }
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
    M.export({ fmt = fmt })
  end, { nargs = '?' })

  create('SmartPlannerConfig', function()
    require('smartplanner.config').open_help()
  end, {})

  create('SmartPlannerSync', function()
    require('smartplanner.views.mini').sync_focus()
  end, {})
end

return M
