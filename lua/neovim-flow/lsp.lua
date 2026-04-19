local M = {}

local servers = { 'basedpyright', 'marksman', 'jsonls' }

M.specs = {
  { 'williamboman/mason.nvim', config = true },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      {
        'williamboman/mason-lspconfig.nvim',
        opts = {
          ensure_installed = servers,
          automatic_enable = true,
        },
      },
    },
    config = function()
      for _, name in ipairs(servers) do
        vim.lsp.enable(name)
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
