local util = require('neovim-flow.util')

local M = {}

M.spec = {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
  opts = {},
}

local function snapshot_dir()
  local gdir = util.git_common_dir()
  if not gdir then return nil end
  local dir = gdir .. '/neovim-flow-session/diff-snapshots'
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
  return dir
end

local function snapshot_path_for(tabnr)
  local dir = snapshot_dir()
  if not dir then return nil end
  return dir .. '/tab-' .. tabnr .. '.vim'
end

local function save_layout()
  local path = snapshot_path_for(vim.api.nvim_tabpage_get_number(0))
  if not path then return nil end
  local saved_so = vim.o.sessionoptions
  vim.o.sessionoptions = 'blank,folds,help,winsize'
  local ok = pcall(vim.cmd, 'mksession! ' .. vim.fn.fnameescape(path))
  vim.o.sessionoptions = saved_so
  return ok and path or nil
end

local function close_other_windows()
  local cur = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= cur and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

local function blank_tab_buffer()
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = scratch })
  close_other_windows()
  vim.api.nvim_win_set_buf(0, scratch)
end

local function diffview_lib()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then return nil end
  return lib
end

local function current_diffview()
  local lib = diffview_lib()
  if not lib then return nil end
  local ok, view = pcall(lib.get_current_view)
  if not ok then return nil end
  return view
end

local function close_diffview()
  local view = current_diffview()
  if view then
    pcall(function() view:close() end)
    local lib = diffview_lib()
    if lib and lib.dispose_view then
      pcall(lib.dispose_view, view)
    end
  end
end

local function in_diff_view()
  return vim.t.neovim_flow_view == 'diff'
end

local function show_agent_layout()
  local snap = vim.t.neovim_flow_diff_snapshot
  blank_tab_buffer()
  if snap and snap ~= '' and vim.fn.filereadable(snap) == 1 then
    local saved_so = vim.o.sessionoptions
    vim.o.sessionoptions = 'blank,folds,help,winsize'
    pcall(vim.cmd, 'silent! source ' .. vim.fn.fnameescape(snap))
    vim.o.sessionoptions = saved_so
  end
  vim.t.neovim_flow_view = 'agent'
end

local function show_diff_layout(wt_path)
  blank_tab_buffer()
  local cmd = 'DiffviewOpen'
  if wt_path and wt_path ~= '' then
    cmd = cmd .. ' -C=' .. vim.fn.fnameescape(wt_path)
  end
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    util.err('diffview failed: ' .. tostring(err))
    return false
  end
  vim.t.neovim_flow_view = 'diff'
  return true
end

function M.open()
  local wt = vim.t.neovim_flow_worktree
  if not wt or wt == '' then
    util.err('not in an agent tab')
    return
  end
  if in_diff_view() then return end
  local snap = save_layout()
  if snap then vim.t.neovim_flow_diff_snapshot = snap end
  show_diff_layout(wt)
end

function M.close()
  if not in_diff_view() then return end
  close_diffview()
  show_agent_layout()
end

function M.toggle()
  local wt = vim.t.neovim_flow_worktree
  if not wt or wt == '' then
    util.err('not in an agent tab')
    return
  end
  if in_diff_view() then
    M.close()
  else
    M.open()
  end
end

function M.current_view()
  return vim.t.neovim_flow_view or 'agent'
end

function M.snapshot_path()
  return vim.t.neovim_flow_diff_snapshot
end

function M.set_snapshot(path)
  vim.t.neovim_flow_diff_snapshot = path
end

function M.set_view(view)
  vim.t.neovim_flow_view = view
end

function M.setup(_)
  vim.api.nvim_create_user_command('NFDiff', function() M.open() end,
    { desc = 'neovim-flow: open diff view for current worktree' })
  vim.api.nvim_create_user_command('NFDiffClose', function() M.close() end,
    { desc = 'neovim-flow: close diff view, restore agent layout' })
  vim.api.nvim_create_user_command('NFDiffToggle', function() M.toggle() end,
    { desc = 'neovim-flow: toggle between diff view and agent view' })
end

return M
