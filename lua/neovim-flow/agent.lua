local M = {}

local function has_session(cwd)
  local home = vim.fn.expand('~')
  local encoded = cwd:gsub('[/\\:]', '-')
  local dir = home .. '/.claude/projects/' .. encoded
  if vim.fn.isdirectory(dir) == 0 then return false end
  return #vim.fn.glob(dir .. '/*.jsonl', false, true) > 0
end

function M.spawn(worktree_path, opts)
  opts = opts or {}
  vim.cmd('botright vsplit')
  local resume = opts.resume and worktree_path and has_session(worktree_path)
  vim.cmd(resume and 'terminal claude --continue' or 'terminal claude')
  vim.t.neovim_flow_term_buf = vim.api.nvim_get_current_buf()
  vim.cmd('startinsert')
  return vim.t.neovim_flow_term_buf
end

function M.focus()
  local buf = vim.t.neovim_flow_term_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_set_current_win(win)
      vim.cmd('startinsert')
      return true
    end
  end
  return false
end

function M.toggle()
  local buf = vim.t.neovim_flow_term_buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_buf(win) == buf then
        vim.api.nvim_win_close(win, false)
        return
      end
    end
    vim.cmd('botright vsplit')
    vim.api.nvim_win_set_buf(0, buf)
    vim.cmd('startinsert')
    return
  end
  local wt = vim.t.neovim_flow_worktree
  if not wt or wt == '' then
    vim.notify('[neovim-flow] not in an agent tab', vim.log.levels.ERROR)
    return
  end
  M.spawn(wt, { resume = true })
end

function M.unfocus()
  local term_buf = vim.t.neovim_flow_term_buf
  if not term_buf then return end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) ~= term_buf then
      vim.api.nvim_set_current_win(win)
      vim.cmd('stopinsert')
      return
    end
  end
end

return M
