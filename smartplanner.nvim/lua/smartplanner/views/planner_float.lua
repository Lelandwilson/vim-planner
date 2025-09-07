-- Floating Planner modal (neo-tree style) with Ctrl-C to close
local planner = require('smartplanner.views.planner')
local dateu = require('smartplanner.util.date')

local M = { win = nil, buf = nil }

local function open_float()
  if M.win and vim.api.nvim_win_is_valid(M.win) then return end
  M.buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  M.win = vim.api.nvim_open_win(M.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'rounded',
    style = 'minimal',
    zindex = 60,
  })
  vim.api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
  vim.keymap.set('n', '<C-c>', function() M.close() end, { buffer = M.buf, nowait = true, desc = 'Close SmartPlanner modal' })
  vim.keymap.set('n', 'q', function() M.close() end, { buffer = M.buf, nowait = true, desc = 'Close SmartPlanner modal' })
end

function M.open(opts)
  open_float()
  -- Render planner content into the floating buffer
  local day = (opts and opts.date) or dateu.today()
  -- Use planner's renderer, but direct into M.buf
  local orig = planner.buf
  planner.buf = M.buf
  planner.open({ date = day })
  planner.buf = orig
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win, M.buf = nil, nil
end

return M
