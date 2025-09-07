
# Neovim Planner — Markdown View (Explained by Screenshot)

This file documents the Markdown planner **as shown in your screenshot** and maps each visual element to concrete parsing/rendering rules the plugin must implement.


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

## 1) What the Screenshot Shows (Markdown Planner)

- **Section headers per day** like `## MONDAY 10/11/25` in ALL CAPS, followed by the date (DD/MM/YY).  
- **Task lines** under each day using a leading bullet and a status token:
  - `- [✓]` → **Done** (green check in your theme).
  - `- [X]` → **Failed/Cancelled** (red X in your theme).
  - `- [50%]` → **In progress with percentage**; should render a progress chip.
  - `- [!!]` → **High priority / urgent**.
- Plain text after the status token is the **task title/description**; may include references like `PR #245`.
- **Weekend block** is allowed (e.g., `## WEEKEND 15,16/11/25`) and may contain a sentence like `No todo's, all clear.`
- Final **bold/italic call‑outs** (e.g., `*** *Important reminder* - you're awesome`) should render emphasized as Markdown.

> The screenshot also shows subtle **row separators** and a **dark themed** buffer with your Catppuccin style; the plugin must not hard‑code colors but should leverage highlighting groups so it adapts to your theme.

### 1.1 Example Snippet (matches the screenshot)

```markdown
# EXAMPLE PLANNER

## MONDAY 10/11/25
- [✓] Daily Stand-up
- [✓] Review PR #245 (API service cleanup)
- [50%] Start working on user-profile feature
- [!!] Follow up with Trevor on server deployment issue
- [✓] Prep for weekly team sync

## TUESDAY 11/11/25
- [✓] Daily Stand-up
- [X] Finish user-profile feature. Blocked by design team on UI mockups. Carry over to tomorrow.
- [✓] Pair programming session with Jane on authentication flow
- [50%] Fix critical bug in the reporting tool
- [✓] Update Jira ticket statuses

## WEDNESDAY 12/11/25
- [✓] Daily Stand-up
- [!!] Review and merge hotfix PR #247
- [✓] Finish user-profile feature (received UI mockups)
- [X] Fix critical bug in the reporting tool. Discovered it's a dev-only issue. Needs a separate task to investigate.
- [50%] Prepare documentation for the new API endpoint

## THURSDAY 13/11/25
- [✓] Daily Stand-up
- [✓] Demo user-profile feature in the sprint review meeting
- [✓] Write unit tests for the new API endpoint
- [✓] Participate in new project brainstorming session
- [!!] Follow up with Product Manager on scope of next sprint

## FRIDAY 14/11/25
- [✓] Daily Stand-up
- [✓] Code freeze for the release
- [✓] Final review of documentation for new API
- [✓] Write up end-of-week summary and hours
- [✓] Tidy up local dev environment

## WEEKEND 15,16/11/25
- No todo's, all clear.

*** *Important reminder* - you're awesome
```

---

## 2) Parsing & Rendering Rules Derived from Screenshot

1. **Day detection**: any H2 (`##`) line that matches `WEEKDAY DD/MM/YY` becomes a **day node** and anchors items that follow until the next day header.
2. **Task tokens**:
   - `[✓]` → `status=done`
   - `[X]` → `status=cancelled`
   - `[!!]` → `status=urgent` (priority high; highlight accordingly)
   - `[\d+%]` → `status=doing` with `progress` int
3. **Ordering**: preserve file order in the view (`order_index` mirrors the line order). Reordering via keymaps writes back to file and JSON shard.
4. **Carry‑over**: if a line contains “Carry over to tomorrow”, provide a quick action to duplicate/move it to the next day.
5. **Weekends**: H2 titled `WEEKEND d1,d2/MM/YY` groups both days; items under it anchor to both dates for calendar linking.
6. **Links**: inline PR/issues remain plaintext; optional Telescope action to open URLs if detected.
7. **Styling**: rely on `render-markdown.nvim` for checkbox/emoji glyph rendering; provide highlight groups for urgent/progress.

---

## 3) Calendar Linking from Markdown

- Every task line inherits the date from its parent day heading.
- Urgent tasks (`[!!]`) should bubble near the top of the **single‑day** list in Calendar (after time‑sorted events).
- Progress (% tokens) may show a small progress indicator in Calendar’s single‑day list.

---

## 4) Suggested Keybindings (fit your style)

- `\\sT` — capture task (modal, floating).
- `\\sx` — toggle status cycle (todo → doing → done → todo).
- `\\sr` — reschedule (date picker → updates heading/date link).
- `]d`/`[d` — jump to next/prev day section.
- `\\sc` — open Calendar (Mode 2); `\\sm` — toggle mini calendar (Mode 1).
