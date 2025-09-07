-- Telescope pickers (§2.6, §8)
local store = require('smartplanner.storage.fs')
local dateu = require('smartplanner.util.date')

local M = {}

function M.setup() end

local function with_telescope(fn)
  local ok, pickers = pcall(require, 'telescope.pickers')
  if not ok then vim.notify('Telescope not found', vim.log.levels.WARN); return end
  return fn(
    pickers,
    require('telescope.finders'),
    require('telescope.config').values,
    require('telescope.previewers')
  )
end

function M.open_picker(which)
  return with_telescope(function(pickers, finders, conf)
    local items = {}
    local range = { start = dateu.today(), ['end'] = dateu.add_days(dateu.today(), 30) }
    if which == 'tasks' then items = store.query_tasks({ range = range })
    elseif which == 'events' then items = store.query_events({ range = range })
    elseif which == 'sprints' then items = store.query_sprints({ range = range })
    elseif which == 'notes' then
      -- reuse tasks query; notes aren’t directly queryable without scanning shards; skip for now
      items = {}
    else items = store.query_tasks({ range = range }) end

    pickers.new({}, {
      prompt_title = 'SmartPlanner ' .. which,
      finder = finders.new_table({
        results = items,
        entry_maker = function(it)
          local txt = it.title or it.name or it.path or it.id
          local date = it.date or it.start_date or ''
          return { value = it, display = string.format('%s  %s', date, txt), ordinal = date .. ' ' .. txt }
        end,
      }),
      sorter = conf.generic_sorter({}),
    }):find()
  end)
end

return M
