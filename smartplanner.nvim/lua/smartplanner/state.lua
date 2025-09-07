local M = {
  cfg = nil,
  focus_day = nil, -- YYYY-MM-DD per §2.5
  caches = {},     -- month shards LRU (future)
}

function M.set_config(cfg) M.cfg = cfg end
function M.get_config() return M.cfg end

function M.set_focus_day(yyyy_mm_dd)
  M.focus_day = yyyy_mm_dd
end

function M.get_focus_day()
  return M.focus_day
end

return M
