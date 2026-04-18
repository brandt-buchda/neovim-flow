local tab = require('neovim-flow.tab')
local agent = require('neovim-flow.agent')

local M = {}

function M.apply(_)
  local map = vim.keymap.set

  map('n', '<leader>an', function() tab.new() end,               { desc = 'agent: new tab/worktree' })
  map('n', '<leader>ad', function() tab.delete_current() end,    { desc = 'agent: delete current' })
  map('n', '<leader>al', function() tab.list() end,              { desc = 'agent: list tabs' })
  map('n', '<leader>af', function() agent.focus() end,           { desc = 'agent: focus terminal' })
  map('n', '<leader>ab', function() agent.unfocus() end,         { desc = 'agent: back to code' })
  map('n', ']a',         function() tab.next_agent_tab(1) end,   { desc = 'agent: next tab' })
  map('n', '[a',         function() tab.next_agent_tab(-1) end,  { desc = 'agent: prev tab' })

  map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'terminal: normal mode' })
end

return M
