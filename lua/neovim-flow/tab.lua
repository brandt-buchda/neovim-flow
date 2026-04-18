local util = require('neovim-flow.util')
local worktree = require('neovim-flow.worktree')
local agent = require('neovim-flow.agent')

local M = {}

local function is_agent_tab(tabpage)
  tabpage = tabpage or 0
  local ok, val = pcall(vim.api.nvim_tabpage_get_var, tabpage, 'neovim_flow_worktree')
  return ok and val ~= nil and val ~= ''
end

function M.setup(_)
  vim.api.nvim_create_user_command('NFNew', function(opts)
    M.new(opts.args ~= '' and opts.args or nil)
  end, { nargs = '?', desc = 'neovim-flow: new agent tab' })

  vim.api.nvim_create_user_command('NFDelete', function()
    M.delete_current()
  end, { desc = 'neovim-flow: delete current agent tab + worktree' })

  vim.api.nvim_create_user_command('NFList', function()
    M.list()
  end, { desc = 'neovim-flow: list agent tabs' })

  vim.api.nvim_create_user_command('NFFocus', function()
    agent.focus()
  end, { desc = 'neovim-flow: focus agent terminal' })

  vim.api.nvim_create_user_command('NFUnfocus', function()
    agent.unfocus()
  end, { desc = 'neovim-flow: back to code window' })
end

local function do_create(input)
  if not input or input == '' then return end
  local wt, err = worktree.create(input)
  if not wt then
    util.err(err)
    return
  end
  vim.cmd('tabnew')
  vim.cmd('tcd ' .. vim.fn.fnameescape(wt.path))
  vim.t.neovim_flow_worktree = wt.path
  vim.t.neovim_flow_name = wt.name
  vim.t.neovim_flow_branch = wt.branch
  vim.t.neovim_flow_root = wt.root
  vim.cmd('Explore')
  agent.spawn(wt.path)
  util.notify('agent tab "' .. wt.name .. '" ready (' .. wt.branch .. ')')
end

function M.new(name)
  if not util.is_git_repo() then
    util.err('not a git repository')
    return
  end
  if name then
    do_create(name)
  else
    vim.ui.input({ prompt = 'worktree name: ' }, do_create)
  end
end

function M.delete_current()
  if not is_agent_tab() then
    util.err('current tab is not an agent tab')
    return
  end
  local name = vim.t.neovim_flow_name
  local path = vim.t.neovim_flow_worktree
  local root = vim.t.neovim_flow_root

  vim.ui.select({ 'yes', 'no' }, {
    prompt = 'Delete agent tab "' .. name .. '" and remove its worktree? (unsaved changes lost)',
  }, function(choice)
    if choice ~= 'yes' then return end
    vim.cmd('tabclose!')
    local ok, err = worktree.remove(path, root)
    if not ok then
      util.err(err)
      return
    end
    util.notify('removed agent "' .. name .. '"')
  end)
end

function M.list()
  local entries = {}
  for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
    if is_agent_tab(tp) then
      local tname = vim.api.nvim_tabpage_get_var(tp, 'neovim_flow_name')
      local tbranch = vim.api.nvim_tabpage_get_var(tp, 'neovim_flow_branch')
      local nr = vim.api.nvim_tabpage_get_number(tp)
      table.insert(entries, {
        tabpage = tp,
        label = ('tab %d  %s  [%s]'):format(nr, tname, tbranch),
      })
    end
  end
  if #entries == 0 then
    util.notify('no agent tabs')
    return
  end
  vim.ui.select(entries, {
    prompt = 'Agent tabs:',
    format_item = function(e) return e.label end,
  }, function(choice)
    if choice then vim.api.nvim_set_current_tabpage(choice.tabpage) end
  end)
end

function M.next_agent_tab(dir)
  local tabs = vim.api.nvim_list_tabpages()
  local cur = vim.api.nvim_get_current_tabpage()
  local idx
  for i, tp in ipairs(tabs) do
    if tp == cur then idx = i; break end
  end
  if not idx then return end
  local n = #tabs
  for step = 1, n do
    local j = ((idx - 1 + step * dir) % n) + 1
    if is_agent_tab(tabs[j]) then
      vim.api.nvim_set_current_tabpage(tabs[j])
      return
    end
  end
end

M.is_agent_tab = is_agent_tab

return M
