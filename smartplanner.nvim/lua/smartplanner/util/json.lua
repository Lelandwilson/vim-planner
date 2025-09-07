-- Robust JSON wrapper (§10 util/json.lua)
local M = {}

function M.encode(tbl)
  local ok, res = pcall(vim.fn.json_encode, tbl)
  if ok then return res end
  return '{}'
end

function M.decode(str)
  if not str or str == '' then return nil end
  local ok, res = pcall(vim.fn.json_decode, str)
  if ok then return res end
  return nil
end

return M
