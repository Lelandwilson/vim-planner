-- Date helpers (§2.5, §7)
local M = {}

function M.today()
  return os.date('%Y-%m-%d')
end

return M
