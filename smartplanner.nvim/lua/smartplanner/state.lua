local M = {
  cfg = nil,
  focus_day = nil, -- YYYY-MM-DD per §2.5
  caches = {},     -- month shards LRU (future)
  last_planner_day = nil,
}

function M.set_config(cfg) M.cfg = cfg end
function M.get_config() return M.cfg end

function M.set_focus_day(yyyy_mm_dd)
  M.focus_day = yyyy_mm_dd
end

function M.get_focus_day()
  return M.focus_day
end

function M.set_last_planner_day(day)
  M.last_planner_day = day
end

function M.get_last_planner_day()
  return M.last_planner_day
end

return M
