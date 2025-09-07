-- CSV exporter (§3.2, §9 export)
local store = require('smartplanner.storage.fs')
local dateu = require('smartplanner.util.date')

local M = {}

function M.export(opts)
  local day = opts.date or dateu.today()
  local y, m = dateu.year_month(day)
  local month = store.read_month(y, m)
  local lines = { 'type,date,title' }
  for _, e in ipairs(month.events or {}) do
    if e.span then
      lines[#lines + 1] = table.concat({ 'event_span', e.start_date .. '->' .. e.end_date, (e.title or e.id) }, ',')
    else
      lines[#lines + 1] = table.concat({ 'event', e.date or '', (e.title or e.id) }, ',')
    end
  end
  for _, t in ipairs(month.tasks or {}) do
    lines[#lines + 1] = table.concat({ 'task', t.date or '', (t.title or '') }, ',')
  end
  for _, n in ipairs(month.notes_index or {}) do
    lines[#lines + 1] = table.concat({ 'note', n.date or '', (n.path or n.id) }, ',')
  end
  vim.cmd('new')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return true
end

return M
