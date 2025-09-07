-- Modal capture/edit UI (§2.6, §6.4) — stub
local M = {}

function M.capture(opts)
  vim.notify('Capture modal (stub): type=' .. tostring(opts and opts.type or 'task'))
end

return M
