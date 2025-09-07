-- Task model (§2.1.1)
local M = {}
function M.new(fields)
  return vim.tbl_extend('force', {
    id = require('smartplanner.util.id').uuid(),
    title = '',
    status = 'todo',
    priority = 0,
    tags = {},
    order_index = 0,
    created_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    updated_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
  }, fields or {})
end
return M
