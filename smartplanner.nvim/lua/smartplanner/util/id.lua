-- UUID util (§10 util/id.lua)
local M = {}

-- Simple UUID v4-ish fallback (not cryptographically strong)
function M.uuid()
  local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  math.randomseed(vim.uv.hrtime())
  return string.gsub(template, '[xy]', function (c)
    local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format('%x', v)
  end)
end

return M
