-- Mini-mode calendar (§2.2, §2.5)
local state = require('smartplanner.state')
local dateu = require('smartplanner.util.date')
local hl = require('smartplanner.ui.highlight')

local M = { win = nil, buf = nil, visible = false }

local function render()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    M.buf = vim.api.nvim_create_buf(false, true)
  end
  local focus = state.get_focus_day() or dateu.today()
  local y, m = dateu.year_month(focus)
  local grid = dateu.month_grid(y, m)
  local header = os.date('%b %Y', os.time({ year = y, month = m, day = 1 }))
  local lines = { ' ' .. header, 'Mo Tu We Th Fr Sa Su' }
  for _, week in ipairs(grid) do
    local row = {}
    for _, day in ipairs(week) do
      local dd = tonumber(day:sub(9, 10))
      local label = string.format('%2d', dd) -- fixed width
      table.insert(row, label)
    end
    lines[#lines + 1] = table.concat(row, ' ')
  end
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  hl.hl_line(M.buf, 0, 'SmartPlannerHeader')
  -- Highlight focus day without changing width
  for w, week in ipairs(grid) do
    for i, day in ipairs(week) do
      if day == focus then
        local lnum = 1 + w -- headers at 0 and 1, weeks start at 2nd index (1-based to 0-based: subtract 1 later)
        local col_start = (i - 1) * 3
        local col_end = col_start + 2
        hl.hl_match(M.buf, lnum, col_start, col_end, 'SmartPlannerToday')
      end
    end
  end
end

local function open_float()
  render()
  local ui = vim.api.nvim_list_uis()[1]
  local width, height = 24, 10
  local row, col = 1, ui.width - width - 2
  M.win = vim.api.nvim_open_win(M.buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'rounded',
    style = 'minimal',
    zindex = 50,
  })
  M.visible = true
end

function M.toggle(opts)
  if M.visible and M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.visible = false
    return
  end
  open_float()
end

function M.sync_focus()
  if M.visible then render() end
end

return M
