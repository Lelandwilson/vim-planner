-- Highlight group setup linking to markdown/render-markdown when available
local M = { ns = vim.api.nvim_create_namespace('SmartPlannerHL') }

local function link(group, target, fallback)
  if vim.fn.hlexists(target) == 1 then
    vim.api.nvim_set_hl(0, group, { link = target })
  else
    vim.api.nvim_set_hl(0, group, { link = fallback })
  end
end

function M.setup()
  -- Prefer render-markdown highlight groups when present, else markdown, else common groups
  link('SmartPlannerHeader', 'RenderMarkdownH1', 'markdownH1')
  link('SmartPlannerWeekday', 'RenderMarkdownH2', 'markdownH2')
  link('SmartPlannerBullet', 'RenderMarkdownListMarker', 'markdownListMarker')
  link('SmartPlannerToday', 'DiffAdd', 'Search')
  link('SmartPlannerSpan', 'WarningMsg', 'Title')
  link('SmartPlannerSprint', 'RenderMarkdownH3', 'Title')
  link('SmartPlannerUrgent', 'DiagnosticError', 'ErrorMsg')
  link('SmartPlannerItem', 'Normal', 'Normal')
end

function M.hl_line(buf, lnum, group)
  vim.api.nvim_buf_add_highlight(buf, M.ns, group, lnum, 0, -1)
end

function M.hl_match(buf, lnum, col_start, col_end, group)
  vim.api.nvim_buf_add_highlight(buf, M.ns, group, lnum, col_start, col_end)
end

return M
