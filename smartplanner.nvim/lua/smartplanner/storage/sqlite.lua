-- Optional backend (§3). Not implemented in skeleton.
local M = {}
function M.not_implemented()
  vim.notify('sqlite backend not implemented (stub)', vim.log.levels.WARN)
end
return M
