local util = require('neovim-flow.util')
local worktree = require('neovim-flow.worktree')

local M = {}

local function session_dir()
  local gdir = util.git_common_dir()
  if not gdir then return nil end
  return gdir .. '/neovim-flow-session'
end

local function meta_path()
  local dir = session_dir()
  return dir and (dir .. '/meta.json') or nil
end

local function ensure_dir(dir)
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

local function write_json(path, data)
  local f = io.open(path, 'w')
  if not f then return end
  f:write(vim.fn.json_encode(data))
  f:close()
end

local function read_json(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local content = f:read('*a')
  f:close()
  if not content or content == '' then return nil end
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then return nil end
  return data
end

local function clear_dir()
  local dir = session_dir()
  if not dir or vim.fn.isdirectory(dir) == 0 then return end
  for _, entry in ipairs(vim.fn.glob(dir .. '/*', false, true)) do
    vim.fn.delete(entry)
  end
end

local function is_agent_tab(tp)
  local ok, val = pcall(vim.api.nvim_tabpage_get_var, tp, 'neovim_flow_worktree')
  return ok and val ~= nil and val ~= ''
end

local function save_tab_layout(tp, path)
  local saved_so = vim.o.sessionoptions
  vim.o.sessionoptions = 'blank,folds,help,winsize'
  local orig = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_set_current_tabpage(tp)
  local ok = pcall(vim.cmd, 'mksession! ' .. vim.fn.fnameescape(path))
  if vim.api.nvim_tabpage_is_valid(orig) then
    vim.api.nvim_set_current_tabpage(orig)
  end
  vim.o.sessionoptions = saved_so
  return ok
end

local function tab_has_real_buffer(tp)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tp)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local bname = vim.api.nvim_buf_get_name(buf)
    local btype = vim.api.nvim_get_option_value('buftype', { buf = buf })
    if bname ~= '' and btype == '' and vim.fn.filereadable(bname) == 1 then
      return true
    end
  end
  return false
end

function M.save()
  local root = util.repo_root()
  if not root then return end
  local dir = session_dir()
  if not dir then return end

  clear_dir()
  ensure_dir(dir)

  local tabs = {}
  local current = vim.api.nvim_get_current_tabpage()
  local active_idx = 1

  for i, tp in ipairs(vim.api.nvim_list_tabpages()) do
    if tp == current then active_idx = #tabs + 1 end
    if is_agent_tab(tp) then
      local wpath = vim.api.nvim_tabpage_get_var(tp, 'neovim_flow_worktree')
      local ok_name, name = pcall(vim.api.nvim_tabpage_get_var, tp, 'neovim_flow_name')
      if wpath and wpath ~= '' then
        table.insert(tabs, {
          kind = 'agent',
          worktree = wpath,
          name = ok_name and name or nil,
        })
      end
    elseif tab_has_real_buffer(tp) then
      local layout = dir .. '/tab-' .. (#tabs + 1) .. '.vim'
      if save_tab_layout(tp, layout) then
        table.insert(tabs, { kind = 'normal', layout = layout })
      end
    end
  end

  if #tabs == 0 then
    clear_dir()
    return
  end

  write_json(meta_path(), {
    version = 1,
    root = root,
    active = active_idx,
    tabs = tabs,
  })
end

local function restore_normal_tab(layout_file, is_first)
  if not is_first then
    vim.cmd('tabnew')
  end
  local saved_so = vim.o.sessionoptions
  vim.o.sessionoptions = 'blank,folds,help,winsize'
  pcall(vim.cmd, 'silent! source ' .. vim.fn.fnameescape(layout_file))
  vim.o.sessionoptions = saved_so
end

local function restore_agent_tab(wt, saved_name, is_first)
  local agent = require('neovim-flow.agent')
  if not is_first then
    vim.cmd('tabnew')
  end
  vim.cmd('tcd ' .. vim.fn.fnameescape(wt.path))
  vim.t.neovim_flow_worktree = wt.path
  vim.t.neovim_flow_name = saved_name or wt.name
  vim.t.neovim_flow_branch = wt.branch
  vim.t.neovim_flow_root = wt.root
  vim.cmd('Explore')
  agent.spawn(wt.path, { resume = true })
end

function M.restore()
  local meta = read_json(meta_path())
  if not meta or type(meta.tabs) ~= 'table' or #meta.tabs == 0 then
    return false
  end

  local root = util.repo_root()
  if not root or root ~= meta.root then return false end

  local wts_by_path = {}
  for _, wt in ipairs(worktree.list_agents(root)) do
    wts_by_path[wt.path] = wt
  end

  local first = true
  local restored = 0

  for _, t in ipairs(meta.tabs) do
    if t.kind == 'agent' then
      local wt = wts_by_path[t.worktree]
      if wt then
        restore_agent_tab(wt, t.name, first)
        first = false
        restored = restored + 1
      end
    elseif t.kind == 'normal' and t.layout and vim.fn.filereadable(t.layout) == 1 then
      restore_normal_tab(t.layout, first)
      first = false
      restored = restored + 1
    end
  end

  if restored == 0 then return false end

  if type(meta.active) == 'number' then
    local tabpages = vim.api.nvim_list_tabpages()
    if tabpages[meta.active] then
      vim.api.nvim_set_current_tabpage(tabpages[meta.active])
    end
  end

  util.notify('restored ' .. restored .. ' tab(s)')
  return true
end

function M.clear()
  clear_dir()
end

function M.should_autoload()
  if vim.fn.argc() > 0 then return false end
  local meta = read_json(meta_path())
  if not meta then return false end
  local root = util.repo_root()
  if not root or root ~= meta.root then return false end
  return true
end

function M.setup()
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function() pcall(M.save) end,
  })

  vim.api.nvim_create_autocmd('VimEnter', {
    nested = true,
    callback = function()
      if M.should_autoload() then
        vim.schedule(function() pcall(M.restore) end)
      end
    end,
  })

  vim.api.nvim_create_user_command('NFSessionRestore', function()
    M.restore()
  end, { desc = 'neovim-flow: restore last session' })

  vim.api.nvim_create_user_command('NFSessionClear', function()
    M.clear()
    util.notify('session cleared')
  end, { desc = 'neovim-flow: clear saved session' })

  vim.api.nvim_create_user_command('NFSessionSave', function()
    M.save()
    util.notify('session saved')
  end, { desc = 'neovim-flow: save session now' })
end

return M
