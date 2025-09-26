-- Delta Manager UI: list/add/edit/delete delta entries; add per-day instance
local store = require('smartplanner.storage')
local idu = require('smartplanner.util.id')
local dateu = require('smartplanner.util.date')

local M = { win = nil, buf = nil }

local function render()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    M.buf = vim.api.nvim_create_buf(false, true)
  end
  local entries = (store.list_delta_entries and store.list_delta_entries()) or {}
  local lines = { '# Delta Entries', '', 'Keys: a add • e edit • d delete • i add instance (today) • q/Ctrl-C close', '' }
  for _, e in ipairs(entries) do
    local val = (e.delta_sec or 0) / 3600.0
    local st = e.start_ts and os.date('%Y-%m-%d', e.start_ts) or 'none'
    local en = e.end_ts and os.date('%Y-%m-%d', e.end_ts) or 'none'
    table.insert(lines, string.format('- %s | +%.2f %s | %s -> %s | id:%s', e.label or 'Delta', val, e.time_unit or 'hrs', st, en, e.id))
  end
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
end

local function open()
  if M.win and vim.api.nvim_win_is_valid(M.win) then return end
  render()
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.7)
  local height = math.floor(ui.height * 0.6)
  local row = math.floor((ui.height - height) / 4)
  local col = math.floor((ui.width - width) / 6)
  M.win = vim.api.nvim_open_win(M.buf, true, { relative = 'editor', width = width, height = height, row = row, col = col, border = 'rounded', style = 'minimal', zindex = 60 })
  vim.keymap.set('n', '<C-c>', function() M.close() end, { buffer = M.buf, nowait = true })
  vim.keymap.set('n', 'q', function() M.close() end, { buffer = M.buf, nowait = true })
  -- add
  vim.keymap.set('n', 'a', function()
    vim.ui.input({ prompt = 'Label: ' }, function(label)
      if not label or label == '' then return end
      vim.ui.input({ prompt = 'Time unit (hrs): ', default = 'hrs' }, function(unit)
        unit = unit or 'hrs'
        vim.ui.input({ prompt = 'Delta per day (e.g., 2.0): ', default = '1.0' }, function(val)
          local n = tonumber(val or '0') or 0
          vim.ui.input({ prompt = 'Start date (YYYY-MM-DD): ', default = dateu.today() }, function(sd)
            vim.ui.input({ prompt = 'End date (YYYY-MM-DD or empty): ', default = '' }, function(ed)
              local st = sd and os.time({ year = tonumber(sd:sub(1,4)), month = tonumber(sd:sub(6,7)), day = tonumber(sd:sub(9,10)), hour = 12 }) or nil
              local en = (ed and ed ~= '') and os.time({ year = tonumber(ed:sub(1,4)), month = tonumber(ed:sub(6,7)), day = tonumber(ed:sub(9,10)), hour = 12 }) or nil
              if store.add_delta_entry then store.add_delta_entry({ label = label, time_unit = unit, delta_sec = math.floor(n * 3600), start_ts = st, end_ts = en }) end
              render()
            end)
          end)
        end)
      end)
    end)
  end, { buffer = M.buf, desc = 'Add delta entry' })
  -- delete
  vim.keymap.set('n', 'd', function()
    local line = vim.api.nvim_get_current_line()
    local id = line:match('id:([%w%-]+)')
    if id and store.delete_delta_entry then store.delete_delta_entry(id) end
    render()
  end, { buffer = M.buf, desc = 'Delete delta entry' })
  -- add instance today
  vim.keymap.set('n', 'i', function()
    local line = vim.api.nvim_get_current_line()
    local id = line:match('id:([%w%-]+)')
    if not id then return end
    vim.ui.input({ prompt = 'Delta today (e.g., 0.5): ', default = '0.5' }, function(val)
      local n = tonumber(val or '0') or 0
      if store.add_delta_instance then store.add_delta_instance({ delta_entry_id = id, day = dateu.today(), delta_sec = math.floor(n * 3600), note = '' }) end
      render()
    end)
  end, { buffer = M.buf, desc = 'Add instance today' })
end

function M.open() open() end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_close(M.win, true) end
  M.win, M.buf = nil, nil
end

return M
