local M = {}

M.spec = {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    require('catppuccin').setup({
      flavour = 'macchiato',
      transparent_background = true,
      term_colors = false,
      integrations = {
        native_lsp = { enabled = true },
        mason = true,
        treesitter = true,
      },
    })
    vim.cmd.colorscheme('catppuccin')

    local clear = { 'Normal', 'NormalNC', 'NormalFloat', 'FloatBorder',
      'SignColumn', 'LineNr', 'CursorLineNr', 'EndOfBuffer',
      'TabLine', 'TabLineFill', 'StatusLine', 'StatusLineNC',
      'VertSplit', 'WinSeparator', 'Pmenu', 'PmenuSbar', 'PmenuThumb',
      'NvimTreeNormal', 'NvimTreeNormalNC' }
    for _, group in ipairs(clear) do
      vim.api.nvim_set_hl(0, group, { bg = 'NONE' })
    end
  end,
}

return M
