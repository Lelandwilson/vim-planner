-- Date helpers (§2.5, §7)
local M = {}

local function to_time(y, m, d)
  return os.time({ year = y, month = m, day = d, hour = 12 }) -- noon avoids DST edge
end

local function from_time(t)
  local dt = os.date('*t', t)
  return dt.year, dt.month, dt.day
end

function M.today()
  return os.date('%Y-%m-%d')
end

function M.parse(yyyy_mm_dd)
  local y, m, d = yyyy_mm_dd:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
  if not y then return nil end
  return tonumber(y), tonumber(m), tonumber(d)
end

function M.format(y, m, d)
  return string.format('%04d-%02d-%02d', y, m, d)
end

function M.add_days(yyyy_mm_dd, delta)
  local y, m, d = M.parse(yyyy_mm_dd)
  local t = to_time(y, m, d) + (delta * 24 * 60 * 60)
  local yy, mm, dd = from_time(t)
  return M.format(yy, mm, dd)
end

function M.weekday(yyyy_mm_dd)
  local y, m, d = M.parse(yyyy_mm_dd)
  local w = os.date('*t', to_time(y, m, d)).wday -- 1=Sun..7=Sat
  return w
end

function M.month_days(year, month)
  local days = {}
  local first = to_time(year, month, 1)
  local next_month = month == 12 and to_time(year + 1, 1, 1) or to_time(year, month + 1, 1)
  local last = next_month - (24 * 60 * 60)
  local _, _, last_day = from_time(last)
  for d = 1, last_day do
    days[#days + 1] = M.format(year, month, d)
  end
  return days
end

-- Returns an array of weeks, each week is array of 7 dates (YYYY-MM-DD), padded from prev/next month.
function M.month_grid(year, month)
  local days = M.month_days(year, month)
  local grid = {}
  local y, m = year, month
  -- find first week starting Monday (or Sunday per locale?). We'll use Monday-start.
  local first_wday = (os.date('*t', os.time({ year = year, month = month, day = 1, hour = 12 })).wday) -- 1=Sun
  local monday_offset = ((first_wday + 5) % 7) -- 0 for Mon, 6 for Sun
  -- prepend previous month days
  local cursor = 1
  local prev_year, prev_month = (month == 1) and (year - 1) or year, (month == 1) and 12 or (month - 1)
  local prev_days = M.month_days(prev_year, prev_month)
  local start_week = {}
  for i = monday_offset, 1, -1 do
    start_week[#start_week + 1] = prev_days[#prev_days - i + 1]
  end
  -- fill remainder of first week with current month days
  while #start_week < 7 do
    start_week[#start_week + 1] = days[cursor]
    cursor = cursor + 1
  end
  grid[#grid + 1] = start_week
  -- fill subsequent weeks
  while cursor <= #days do
    local week = {}
    for i = 1, 7 do
      if cursor <= #days then
        week[#week + 1] = days[cursor]
        cursor = cursor + 1
      else
        -- pad with next month
        local base_t = to_time(year, month, #days)
        local t = base_t + (i * 24 * 60 * 60)
        local yy, mm, dd = from_time(t)
        week[#week + 1] = M.format(yy, mm, dd)
      end
    end
    grid[#grid + 1] = week
  end
  return grid
end

function M.year_month(yyyy_mm_dd)
  local y, m = yyyy_mm_dd:match('^(%d%d%d%d)%-(%d%d)')
  return tonumber(y), tonumber(m)
end

function M.in_month(yyyy_mm_dd, year, month)
  local y, m = M.year_month(yyyy_mm_dd)
  return y == year and m == month
end

function M.range_intersect(a_start, a_end, b_start, b_end)
  return not (a_end < b_start or b_end < a_start)
end

return M
