-- Modal capture/edit UI (§2.6, §6.4)
local idu = require('smartplanner.util.id')
local store = require('smartplanner.storage.fs')
local dateu = require('smartplanner.util.date')

local M = {}

local function input(prompt, default, cb)
  vim.ui.input({ prompt = prompt .. ' ', default = default }, function(val)
    cb(val)
  end)
end

local function capture_task()
  local task = { id = idu.uuid(), status = 'todo', priority = 1, tags = {} }
  input('Task title:', '', function(title)
    if not title or title == '' then return end
    task.title = title
    input('Date (YYYY-MM-DD):', dateu.today(), function(date)
      task.date = date or dateu.today()
      store.add_task(task)
      vim.notify('Task added: ' .. task.title)
    end)
  end)
end

local function capture_event()
  local ev = { id = idu.uuid(), span = false, allday = true, priority = 1 }
  input('Event title:', '', function(title)
    if not title or title == '' then return end
    ev.title = title
    input('Date (YYYY-MM-DD) or range (start,end):', dateu.today(), function(date)
      if not date then return end
      local s, e = date:match('^(%d%d%d%d%-%d%d%-%d%d),(%d%d%d%d%-%d%d%-%d%d)$')
      if s and e then ev.span = true; ev.start_date = s; ev.end_date = e else ev.date = date end
      store.add_event(ev)
      vim.notify('Event added: ' .. ev.title)
    end)
  end)
end

local function capture_note()
  local n = { id = idu.uuid(), tags = {} }
  input('Note title:', '', function(title)
    if not title or title == '' then return end
    n.title = title
    input('Date (YYYY-MM-DD):', dateu.today(), function(date)
      n.date = date or dateu.today()
      input('Body (optional):', '', function(body)
        n.body = body or ''
        store.add_note(n)
        vim.notify('Note added: ' .. n.title)
      end)
    end)
  end)
end

local function capture_sprint()
  local sp = { id = idu.uuid() }
  input('Sprint name:', '', function(name)
    if not name or name == '' then return end
    sp.name = name
    input('Start date (YYYY-MM-DD):', dateu.today(), function(sd)
      sp.start_date = sd or dateu.today()
      input('End date (YYYY-MM-DD):', dateu.add_days(sp.start_date, 4), function(ed)
        sp.end_date = ed or sp.start_date
        store.add_sprint(sp)
        vim.notify('Sprint added: ' .. sp.name)
      end)
    end)
  end)
end

function M.capture(opts)
  local t = (opts and opts.type) or 'task'
  if t == 'task' then return capture_task()
  elseif t == 'event' then return capture_event()
  elseif t == 'note' then return capture_note()
  elseif t == 'sprint' then return capture_sprint()
  else
    vim.notify('Unknown capture type: ' .. tostring(t), vim.log.levels.ERROR)
  end
end

return M
