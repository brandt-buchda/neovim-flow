local M = {}

function M.apply(_)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  local o = vim.opt
  o.number = true
  o.relativenumber = true
  o.signcolumn = 'yes'
  o.mouse = 'a'
  o.termguicolors = true
  o.clipboard = 'unnamedplus'
  o.splitright = true
  o.splitbelow = true
  o.expandtab = true
  o.shiftwidth = 4
  o.tabstop = 4
  o.smartindent = true
  o.ignorecase = true
  o.smartcase = true
  o.undofile = true
  o.scrolloff = 8
  o.updatetime = 250
  o.timeoutlen = 400

  vim.api.nvim_create_autocmd('TermOpen', {
    callback = function()
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.signcolumn = 'no'
    end,
  })
end

return M
