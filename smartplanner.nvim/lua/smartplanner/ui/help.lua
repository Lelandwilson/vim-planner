local M = { win = nil, buf = nil }

local function planner_help(prefix)
  return {
    'SmartPlanner — Planner Keys',
    '',
    string.format('%sp  Open Planner    %sf  Floating Planner', prefix, prefix),
    string.format('%sl  Next Day        %sh  Prev Day',       prefix, prefix),
    string.format('%sx  Toggle Status   %sr  Reschedule',     prefix, prefix),
    string.format('%sk  Move Up         %sj  Move Down',      prefix, prefix),
    string.format('%sD  Delete Item     %si  Rename Label',   prefix, prefix),
    string.format('%st  Capture Task    %se  Capture Event',  prefix, prefix),
    string.format('%sn  Capture Note    %ss  Capture Sprint', prefix, prefix),
    string.format('%sd  Calendar Day    %sw  Calendar Week',  prefix, prefix),
    string.format('%sc  Calendar Month  %sm  Mini Toggle',    prefix, prefix),
    string.format('%sq  Quick Inbox     zA Collapse All',     prefix),
    'zW Expand Week      zR Expand Range',
    string.format('%sd  Delta Manager   %si  Delta Instance (per-day)', prefix, prefix),
    '',
    'Enter on a day heading to expand/collapse. q/Ctrl-C to close.',
  }
end

local function calendar_help(prefix)
  return {
    'SmartPlanner — Calendar Keys',
    '',
    string.format('%sc Month (cycle views)', prefix),
    string.format('%sw Week  %sd Day',       prefix, prefix),
    string.format('%sp Open Planner  %sm Mini Toggle', prefix, prefix),
    '',
    'Enter on a cell to jump; q/Ctrl-C to close.',
  }
end

local function open(lines)
  if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_close(M.win, true) end
  M.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  local ui = vim.api.nvim_list_uis()[1]
  local width = 54
  local height = #lines + 2
  -- Bottom-right: 2 lines padding from bottom/right, clamp to keep on screen
  local row = math.max(1, ui.height - height - 2)
  local col = math.max(1, ui.width - width - 2)
  M.win = vim.api.nvim_open_win(M.buf, false, { relative = 'editor', width = width, height = height, row = row, col = col, border = 'rounded', style = 'minimal', zindex = 70 })
  vim.keymap.set('n', 'q', function() M.close() end, { buffer = M.buf, nowait = true })
  vim.keymap.set('n', '<C-c>', function() M.close() end, { buffer = M.buf, nowait = true })
end

function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then return M.close() end
  -- Display <l> as shorthand for <leader> in the help overlay
  local prefix = '<l>' .. ((require('smartplanner.config').get().keymaps_prefix) or 's')
  local name = vim.api.nvim_buf_get_name(0)
  if name:match('SmartPlanner: Planner') then
    open(planner_help(prefix))
  elseif name:match('SmartPlanner: Calendar') then
    open(calendar_help(prefix))
  else
    open(planner_help(prefix))
  end
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_close(M.win, true) end
  M.win, M.buf = nil, nil
end

return M
