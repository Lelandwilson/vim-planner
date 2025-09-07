
# Neovim Planner — Calendar & Sprint View (Explained by Screenshot)

This file documents the calendar & sprint planning view **as shown in your spreadsheet‑style screenshot**, and maps colors/labels/positions to the plugin behavior.


## Your Current Setup & Preferences (from initial query)

- **Plugins you already use**:  
  `alpha.lua`, `autopairs.lua`, `catppuccin.lua`, `completions.lua`, `git-stuff.lua`, `gitsigns.lua`, `lsp-config.lua`, `lsp-config.lua.bkp`, `mini.lua`, `neo-tree.lua`, `none-ls.lua`, `nvim-tmux-navigation.lua`, `oil.lua`, `render-markdown.lua`, `swagger-preview.lua`, `telescope.lua`, `treesitter.lua`, `vim-test.lua`.
- **Modal/Popup preference**: you love **floating modals** (e.g., Telescope, neo-tree popups); keep the planner’s UI consistent with this style.
- **Markdown-first**: you use **render-markdown.nvim** and keep **planner & notes** as Markdown by default.
- **Lazy.nvim setup** (snippet you provided):
  ```lua
  -- ~/.config/nvim/init.lua
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git", "clone", "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
  require("vim-options")
  require("lazy").setup("plugins")
  ```
- **Keybindings & options** (excerpt):
  ```lua
  -- ~/.config/nvim/vim-options.lua
  vim.cmd("set expandtab")
  vim.cmd("set tabstop=2")
  vim.cmd("set softtabstop=2")
  vim.cmd("set shiftwidth=2")
  vim.g.mapleader = " "
  vim.g.background = "light"
  vim.opt.swapfile = false
  vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
  vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
  vim.keymap.set('n', '<c-h>', ':wincmd h<CR>')
  vim.keymap.set('n', '<c-l>', ':wincmd l<CR>')
  vim.keymap.set('n', '<leader>h>', ':nohlsearch<CR>')
  vim.wo.number = true
  vim.wo.relativenumber = true
  ```

### Calendar Popup Modes (required behavior)
- **Mode 0** — Hidden (not visible).
- **Mode 1** — **Mini view** floating in top‑right of the Neovim window, shows the current month and **highlights today** — quick “what date is Wednesday?” reference.
- **Mode 2** — **Expanded view** (full‑screen modal) with a **toggle** between **Day/Week/Month** detail.

> All day entries in the Markdown planner must be linked to the corresponding calendar date(s). Multi‑day spans (sprints) appear above single‑day items in the calendar.


---

## 1) What the Screenshot Shows (Calendar Month)

- **Month header**: `Aug‑25` centered on the top bar.
- **Weekday headers**: `MONDAY ... SUNDAY` in a cyan/blue band.
- **Grey cells**: days **outside the current month** — visually de‑emphasized.
- **Green cell “Today!”**: the 25th is highlighted as **today**.
- **Colored events**:\n
  - **Red block** on **Fri 15** labeled **“DR Failover Test”** → high‑severity, all‑day event.\n
  - **Amber/Yellow block** on **Fri 22** labeled **“DR Failback Test”** → medium severity, all‑day event.\n
  - **Text note** on **Wed 13** “Follow up Api prvider” → single‑day task/note.\n
  - **Label** on **Fri 27** “Sprint 8 to prod” → milestone.\n
- **Right‑hand notes box** titled **“Sprint 8 notes:”** with bullets `BFO‑121/122/125` — an **adjacent notes pane** associated with the sprint.

### 1.1 How the Plugin Should Render This

- **Top band** (spans & sprints): if a sprint spans many days, it appears **above** daily items, stretching across its date range with continuation chevrons if clipped.
- **Severity colors**: map to highlight groups (no hard‑coded colors); e.g. `CalendarEventUrgent` (red), `CalendarEventWarning` (amber), `CalendarToday` (green ring).
- **Notes pane**: in Expanded Mode (Mode 2), a **right sidebar** can show **sprint notes** for the focused week or selected sprint, populated from `notes_index` or from an attached sprint metadata file.

---

## 2) Data Encodings for the Screenshot Items

```json
{
  "month": "2025-08",
  "events": [
    { "id":"e-dr-failover", "title":"DR Failover Test", "date":"2025-08-15", "allday":true, "severity":"urgent", "span":false },
    { "id":"e-dr-failback", "title":"DR Failback Test", "date":"2025-08-22", "allday":true, "severity":"warning", "span":false }
  ],
  "tasks": [
    { "id":"t-api-followup", "title":"Follow up Api prvider", "date":"2025-08-13", "priority":2 }
  ],
  "milestones": [
    { "id":"m-sprint8-prod", "title":"Sprint 8 to prod", "date":"2025-08-27" }
  ],
  "sprints": [
    { "id":"s8", "name":"Sprint 8", "start_date":"2025-08-18", "end_date":"2025-08-29", "notes":["BFO-121","BFO-122","BFO-125"] }
  ]
}
```

---

## 3) Interactions Matching the Screenshot Workflow

- **Mode 1 (Mini)**: shows the month, highlights **today** (25). Quick nav to dates; click/enter on a date jumps the Markdown buffer to that day heading.
- **Mode 2 (Expanded)**:\n
  - Toggle **Day/Week/Month** views.\n
  - Selecting **Sprint 8** focuses its band; the **notes pane** displays bullets `BFO‑121/122/125`.\n
  - Selecting 15th or 22nd reveals event details (severity color applied).\n
- **Link‑back**: choosing a date cell opens/jumps to that date in the Markdown planner; choosing a task opens it inline for edit.

---

## 4) Visual Rules Derived from the Spreadsheet

- **Out‑of‑month days**: deemphasize (grey tone) but **clickable** for quick shift into adjacent months.
- **Today**: green ring or background per theme (`CalendarToday` group).
- **Single‑day items** live **below** the top band; order by time → priority → order_index.
- **Milestones** can render as a **pill** with a small marker dot at the cell’s top (but below spans).

---

## 5) Suggested Keybindings for Calendar

- `\sc` — open expanded calendar (Mode 2).
- `\sm` — toggle mini calendar (Mode 1).
- `]w`/`[w` — next/prev week band.
- `]m`/`[m` — next/prev month.
- `<CR>` — open selected date; `e` — edit item; `S` — create sprint span; `A` — add event.

---

**End of document.**
