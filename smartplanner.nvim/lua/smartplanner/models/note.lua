-- Note model (§2.1.3)
local M = {}
function M.new(fields)
  return vim.tbl_extend('force', {
    id = require('smartplanner.util.id').uuid(),
    date = nil,
    body = '',
    links = {},
  }, fields or {})
end
return M
