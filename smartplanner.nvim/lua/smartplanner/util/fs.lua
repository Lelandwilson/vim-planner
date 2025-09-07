-- FS helpers (§10 util/fs.lua)
local M = {}

function M.mkdirp(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, 'p')
  end
end

function M.read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local data = f:read('*a')
  f:close()
  return data
end

function M.write_file(path, contents)
  local f = assert(io.open(path, 'w'))
  f:write(contents)
  f:close()
end

return M
