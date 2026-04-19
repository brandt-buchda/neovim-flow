local M = {}

function M.spawn(_worktree_path, opts)
  opts = opts or {}
  vim.cmd('botright vsplit')
  local cmd = opts.resume and 'terminal claude --continue' or 'terminal claude'
  vim.cmd(cmd)
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
