-- Telescope pickers (§2.6, §8) — minimal glue
local M = {}

function M.setup()
  -- In a full implementation, register extensions and pickers here
end

function M.open_picker(which)
  vim.notify('Telescope picker (stub): ' .. tostring(which))
end

return M
