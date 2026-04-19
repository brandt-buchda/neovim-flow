local M = {}

local servers = { 'basedpyright', 'marksman', 'jsonls' }

M.specs = {
  { 'williamboman/mason.nvim', config = true },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      ensure_installed = servers,
      automatic_installation = true,
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'williamboman/mason-lspconfig.nvim' },
    config = function()
      local lsp = require('lspconfig')
      for _, name in ipairs(servers) do
        lsp[name].setup({})
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local buf = args.buf
          local map = function(m, lhs, rhs, desc)
            vim.keymap.set(m, lhs, rhs, { buffer = buf, desc = desc })
          end
          map('n', 'gd', vim.lsp.buf.definition, 'lsp: definition')
          map('n', 'gr', vim.lsp.buf.references, 'lsp: references')
          map('n', 'K',  vim.lsp.buf.hover,      'lsp: hover')
          map('n', '<leader>rn', vim.lsp.buf.rename,      'lsp: rename')
          map('n', '<leader>ca', vim.lsp.buf.code_action, 'lsp: code action')
          map('n', '[d', vim.diagnostic.goto_prev, 'diag: prev')
          map('n', ']d', vim.diagnostic.goto_next, 'diag: next')
        end,
      })
    end,
  },
}

return M
