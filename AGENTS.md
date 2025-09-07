# Repository Guidelines

## Project Structure & Module Organization
- Docs-first root: `nvim-planner-spec.md` (source of truth), `nvim-planner-*-screenshot-mapped.md`, and `folders.md`.
- Plugin code lives under `smartplanner.nvim/` mirroring §10 of the spec: `lua/smartplanner/{config,state,storage,models,views,ui,util,export}`.
- Keep examples and assets in `assets/` (create when needed). Use kebab-case filenames and the prefixes `nvim-planner-` or `smartplanner-` for clarity.

## Build, Test, and Development Commands
- Local dev (Lazy.nvim): add `{ "local/smartplanner.nvim", config = function() require("smartplanner").setup({ keymaps = "default" }) end }` to your plugin list.
- Neovim smoke test: `nvim -c "lua require('smartplanner').open_planner({})"`.
- Markdown lint/format (optional): `markdownlint **/*.md`, `prettier -w **/*.md`.
- Validate JSON examples: `jq . < file.json`.

## Coding Style & Naming Conventions
- Markdown: use `#`, `##`, `###`; short sections; fenced blocks with language tags (`lua`, `json`, `markdown`).
- Lua: 2-space indent; snake_case locals; module paths match folders; no hard-coded colors—use highlight groups (Catppuccin-friendly).
- Filenames: kebab-case; screenshot guides follow `nvim-planner-<view>--screenshot-mapped.md`.

## Testing Guidelines
- Align all changes with the spec: update §3 Storage, §4 Config API, §6 UI rules, §9 Public API, and §20 Example JSON when behavior changes.
- Keep examples runnable: `jq` for JSON; load Lua snippets with `nvim -Nu NONE -c "lua dofile('path.lua')"`.
- Implementation repo tests (later): `plenary.nvim` + `busted`, files named `*_spec.lua`.

## Commit & Pull Request Guidelines
- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- PRs: clear description, link spec sections (e.g., “§2.4 ordering”), include screenshots or minimal demos for UI changes.
- Keep diffs small and focused; update both screenshot-mapped docs if a UI rule changes in one view.

## Agent-Specific & Security Notes
- Follow popup modes 0/1/2 and top-band rules for spans; prefer the screenshot-mapped conventions when in doubt.
- Local-only by default; do not commit secrets. Use Windows- and *nix-safe paths (e.g., `vim.fn.stdpath('data')`).
