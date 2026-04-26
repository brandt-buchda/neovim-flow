local util = require('neovim-flow.util')

local M = {}

M.spec = {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
  opts = {},
}

local function tp_get(tp, name)
  local ok, val = pcall(vim.api.nvim_tabpage_get_var, tp, name)
  if not ok then return nil end
  return val
end

local function tp_set(tp, name, val)
  pcall(vim.api.nvim_tabpage_set_var, tp, name, val)
end

local function tp_del(tp, name)
  pcall(vim.api.nvim_tabpage_del_var, tp, name)
end

local function valid_tp(tp)
  return tp and vim.api.nvim_tabpage_is_valid(tp)
end

local function is_agent_tab(tp)
  local val = tp_get(tp, 'neovim_flow_worktree')
  return val ~= nil and val ~= ''
end

local function partner_of(tp)
  local val = tp_get(tp, 'neovim_flow_diff_partner')
  if valid_tp(val) then return val end
  if val ~= nil then tp_del(tp, 'neovim_flow_diff_partner') end
  return nil
end

local function owner_of(tp)
  local val = tp_get(tp, 'neovim_flow_diff_owner')
  if valid_tp(val) then return val end
  if val ~= nil then tp_del(tp, 'neovim_flow_diff_owner') end
  return nil
end

local function pair(agent_tp, diff_tp)
  tp_set(agent_tp, 'neovim_flow_diff_partner', diff_tp)
  tp_set(diff_tp, 'neovim_flow_diff_owner', agent_tp)
end

local function close_diffview_here()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then return end
  local view_ok, view = pcall(lib.get_current_view)
  if view_ok and view then
    pcall(function() view:close() end)
  end
end

function M.open()
  local cur = vim.api.nvim_get_current_tabpage()
  local owner = owner_of(cur)
  if owner then
    vim.api.nvim_set_current_tabpage(owner)
    return
  end
  if not is_agent_tab(cur) then
    util.err('not in an agent tab')
    return
  end
  local existing = partner_of(cur)
  if existing then
    vim.api.nvim_set_current_tabpage(existing)
    return
  end
  local wt = vim.t.neovim_flow_worktree
  local name = vim.t.neovim_flow_name
  local cmd = 'DiffviewOpen'
  if wt and wt ~= '' then
    cmd = cmd .. ' -C=' .. vim.fn.fnameescape(wt)
  end
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    util.err('diffview failed: ' .. tostring(err))
    return
  end
  local diff_tp = vim.api.nvim_get_current_tabpage()
  if diff_tp == cur then
    util.err('diffview did not open a new tab')
    return
  end
  pair(cur, diff_tp)
  if name and name ~= '' then
    tp_set(diff_tp, 'neovim_flow_name', 'diff: ' .. name)
  end
end

function M.close()
  local cur = vim.api.nvim_get_current_tabpage()
  local owner = owner_of(cur)
  if owner then
    close_diffview_here()
    if valid_tp(cur) then
      pcall(vim.cmd, 'tabclose')
    end
    if valid_tp(owner) then
      vim.api.nvim_set_current_tabpage(owner)
      tp_del(owner, 'neovim_flow_diff_partner')
    end
    return
  end
  local partner = partner_of(cur)
  if not partner then return end
  vim.api.nvim_set_current_tabpage(partner)
  close_diffview_here()
  if valid_tp(partner) then
    pcall(vim.cmd, 'tabclose')
  end
  if valid_tp(cur) then
    vim.api.nvim_set_current_tabpage(cur)
  end
  tp_del(cur, 'neovim_flow_diff_partner')
end

function M.toggle()
  local cur = vim.api.nvim_get_current_tabpage()
  if owner_of(cur) or partner_of(cur) then
    M.close()
  else
    M.open()
  end
end

function M.has_open_diff(tp)
  return partner_of(tp or vim.api.nvim_get_current_tabpage()) ~= nil
end

function M.is_diff_tab(tp)
  return owner_of(tp or vim.api.nvim_get_current_tabpage()) ~= nil
end

function M.setup(_)
  vim.api.nvim_create_user_command('NFDiff', function() M.open() end,
    { desc = 'neovim-flow: open diff view for current worktree' })
  vim.api.nvim_create_user_command('NFDiffClose', function() M.close() end,
    { desc = 'neovim-flow: close diff view, return to agent tab' })
  vim.api.nvim_create_user_command('NFDiffToggle', function() M.toggle() end,
    { desc = 'neovim-flow: toggle between diff view and agent tab' })
end

return M
