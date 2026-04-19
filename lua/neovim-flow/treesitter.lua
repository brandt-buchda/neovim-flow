local M = {}

M.spec = {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs',
  opts = {
    ensure_installed = {
      'lua', 'vim', 'vimdoc', 'bash',
      'python', 'markdown', 'markdown_inline', 'json', 'jsonc',
      'sql', 'html', 'css', 'xml', 'yaml', 'javascript', 'typescript', 'tsx',
      'toml', 'regex', 'dockerfile',
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  },
}

return M
