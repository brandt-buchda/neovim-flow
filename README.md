# neovim-flow

A portable Neovim config for **parallel, tab-isolated agentic development** with the Claude CLI.

Each Neovim tab is one git worktree running one Claude agent. Open a tab, an isolated worktree and agent are spawned; close the tab, the worktree is cleaned up. Multiple tabs = multiple agents working on separate things at once.

## Requirements

- Neovim 0.10+
- `git` on PATH
- `claude` CLI on PATH (Claude Code)
- A git repo with an `origin/main` branch (agents branch off it)

## Install

Clone and launch via `NVIM_APPNAME` so this coexists with any other Neovim config:

```bash
git clone <this-repo> ~/.config/neovim-flow       # or %LOCALAPPDATA%\neovim-flow on Windows
NVIM_APPNAME=neovim-flow nvim
```

## Model

- **Tab 1** is the parent repo view (normal Neovim, no agent).
- **Every other tab** is an agent tab: a git worktree at `<repo>/.worktrees/<name>/` on branch `agent/<name>` forked from `origin/main`.
- `.worktrees/` is auto-appended to `.git/info/exclude` (local-only, no commit needed).
- If `nvim` is launched outside a git repo, agent commands error cleanly; the rest of the config still loads.

## Keymaps

Leader is `<Space>`.

| Keymap        | Action                                               |
| ------------- | ---------------------------------------------------- |
| `<leader>an`  | New agent tab (prompts for name, fetches, creates)   |
| `<leader>ad`  | Delete current agent tab + remove its worktree       |
| `<leader>al`  | List agent tabs (picker jumps to selection)          |
| `<leader>af`  | Focus the agent terminal in current tab              |
| `<leader>ab`  | Back to code window (unfocus terminal)               |
| `]a` / `[a`   | Next / previous agent tab                            |
| `<Esc><Esc>`  | Exit terminal insert mode (terminal-mode)            |

## Commands

Same behaviors as the keymaps, for scripting or muscle memory:

| Command          | Action                                      |
| ---------------- | ------------------------------------------- |
| `:NFNew [name]`  | New agent tab. Name optional (will prompt). |
| `:NFDelete`      | Delete current agent tab + worktree.        |
| `:NFList`        | List agent tabs.                            |
| `:NFFocus`       | Focus agent terminal.                       |
| `:NFUnfocus`     | Back to code window.                        |

## Architecture

```
neovim-flow/
  init.lua                     bootstrap
  lua/neovim-flow/
    init.lua                   setup()
    config.lua                 options, leader, term autocmds
    keymaps.lua                <leader>a* bindings
    worktree.lua               git worktree add/remove/list
    agent.lua                  spawn claude in terminal split
    tab.lua                    tab <-> worktree <-> agent glue
    util.lua                   notify, git root, exclude file
```

Tab state is stored in tab-local vars (`vim.t.neovim_flow_*`) so each tab fully owns its worktree metadata: path, name, branch, terminal buffer, repo root.

## Known limits (v1)

- Claude runs as an interactive terminal. Structured event integration (`claude -p --output-format stream-json`) is a future layer on top of `agent.lua`.
- Closing a tab with `:tabclose` instead of `<leader>ad` leaves the worktree on disk. Clean up with `git worktree remove` or reopen and use `<leader>ad`.
- No plugin manager yet; pure-Lua native Neovim. A manager (lazy.nvim) will be added when the first plugin dependency appears.
- Zero-plugin file explorer uses netrw (`:Explore`) in the left window of each agent tab.
