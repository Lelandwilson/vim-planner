-- Storage router: picks fs or sqlite based on config
local cfg = require('smartplanner.config').get()
local backend = (cfg.storage and cfg.storage.backend) or 'fs'

local M
if backend == 'sqlite' then
  local ok, sql = pcall(require, 'smartplanner.storage.sqlite')
  if ok then M = sql else M = require('smartplanner.storage.fs') end
else
  M = require('smartplanner.storage.fs')
end

return M
