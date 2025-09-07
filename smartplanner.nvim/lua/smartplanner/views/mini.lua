-- Mini-mode calendar (§2.2, §2.5) — stub
local state = require('smartplanner.state')

local M = { win = nil, buf = nil, visible = false }

local function render()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    M.buf = vim.api.nvim_create_buf(false, true)
  end
  local day = state.get_focus_day() or os.date('%Y-%m-%d')
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, {
    'Mini Calendar (stub)',
    'Focus day: ' .. day,
    '(Mode 1: floating top-right)'
  })
end

local function open_float()
  render()
  local ui = vim.api.nvim_list_uis()[1]
  local width, height = 24, 6
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
