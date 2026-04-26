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
    if not entry:match('debug%.log$') then
      vim.fn.delete(entry)
    end
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

local function debug_log(msg)
  local dir = session_dir()
  if not dir then return end
  ensure_dir(dir)
  local f = io.open(dir .. '/debug.log', 'a')
  if not f then return end
  f:write(os.date('%Y-%m-%d %H:%M:%S') .. ' ' .. tostring(msg) .. '\n')
  f:close()
end

function M.save()
  local root = util.repo_root()
  if not root then
    debug_log('save: no repo root')
    return
  end
  local dir = session_dir()
  if not dir then
    debug_log('save: no session dir')
    return
  end

  ensure_dir(dir)
  debug_log('save: starting, root=' .. root)
  clear_dir()

  local tabs = {}
  local current = vim.api.nvim_get_current_tabpage()
  local active_idx = 1
  local all_tabs = vim.api.nvim_list_tabpages()
  debug_log('save: ' .. #all_tabs .. ' tab(s) open')

  for i, tp in ipairs(all_tabs) do
    if tp == current then active_idx = #tabs + 1 end
    local is_agent = is_agent_tab(tp)
    local ok_wt, wpath = pcall(vim.api.nvim_tabpage_get_var, tp, 'neovim_flow_worktree')
    debug_log(string.format('  tab %d: agent=%s wt=%s', i, tostring(is_agent), tostring(ok_wt and wpath or 'none')))
    if is_agent then
      local ok_name, name = pcall(vim.api.nvim_tabpage_get_var, tp, 'neovim_flow_name')
      local ok_partner, partner = pcall(vim.api.nvim_tabpage_get_var, tp, 'neovim_flow_diff_partner')
      local has_diff = ok_partner and partner ~= nil and vim.api.nvim_tabpage_is_valid(partner)
      if ok_wt and wpath and wpath ~= '' then
        local layout = dir .. '/tab-' .. (#tabs + 1) .. '.vim'
        local ok = save_tab_layout(tp, layout)
        debug_log('    agent tab layout save: ' .. tostring(ok))
        table.insert(tabs, {
          kind = 'agent',
          worktree = wpath,
          name = ok_name and name or nil,
          layout = ok and layout or nil,
          view = has_diff and 'diff' or 'agent',
        })
      end
    elseif tab_has_real_buffer(tp) then
      local layout = dir .. '/tab-' .. (#tabs + 1) .. '.vim'
      local ok = save_tab_layout(tp, layout)
      debug_log('    normal tab layout save: ' .. tostring(ok))
      if ok then
        table.insert(tabs, { kind = 'normal', layout = layout })
      end
    end
  end

  debug_log('save: captured ' .. #tabs .. ' tab(s)')

  if #tabs == 0 then
    debug_log('save: bailed, nothing to save (preserving existing meta)')
    return
  end

  write_json(meta_path(), {
    version = 1,
    root = root,
    active = active_idx,
    tabs = tabs,
  })
  debug_log('save: wrote meta.json')
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

local function restore_agent_tab(wt, saved_name, layout_file, view, is_first)
  local agent = require('neovim-flow.agent')
  local diff = require('neovim-flow.diff')
  if not is_first then
    vim.cmd('tabnew')
  end
  vim.cmd('tcd ' .. vim.fn.fnameescape(wt.path))
  vim.t.neovim_flow_worktree = wt.path
  vim.t.neovim_flow_name = saved_name or wt.name
  vim.t.neovim_flow_branch = wt.branch
  vim.t.neovim_flow_root = wt.root
  if layout_file and vim.fn.filereadable(layout_file) == 1 then
    local saved_so = vim.o.sessionoptions
    vim.o.sessionoptions = 'blank,folds,help,winsize'
    pcall(vim.cmd, 'silent! source ' .. vim.fn.fnameescape(layout_file))
    vim.o.sessionoptions = saved_so
  else
    vim.cmd('Explore')
  end
  agent.spawn(wt.path, { resume = true })
  if view == 'diff' then
    local agent_tp = vim.api.nvim_get_current_tabpage()
    diff.open()
    if vim.api.nvim_tabpage_is_valid(agent_tp) then
      vim.api.nvim_set_current_tabpage(agent_tp)
    end
  end
end

function M.restore()
  local meta = read_json(meta_path())
  if not meta or type(meta.tabs) ~= 'table' or #meta.tabs == 0 then
    return false
  end

  local root = util.repo_root()
  if not root then return false end

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
        restore_agent_tab(wt, t.name, t.layout, t.view, first)
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
  if not meta or type(meta.tabs) ~= 'table' or #meta.tabs == 0 then
    return false
  end
  return util.repo_root() ~= nil
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
