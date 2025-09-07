-- Event model (§2.1.2)
local M = {}
function M.new(fields)
  return vim.tbl_extend('force', {
    id = require('smartplanner.util.id').uuid(),
    title = '',
    span = false,
    allday = false,
    priority = 0,
    order_index = 0,
  }, fields or {})
end
return M
