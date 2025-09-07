-- Sprint model (§2.1.4)
local M = {}
function M.new(fields)
  return vim.tbl_extend('force', {
    id = require('smartplanner.util.id').uuid(),
    name = '',
    start_date = nil,
    end_date = nil,
    milestones = {},
    color = nil,
  }, fields or {})
end
return M
