local M = {}

M.spec = {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Telescope',
  opts = {},
}

function M.find_files()
  require('telescope.builtin').find_files({ hidden = true })
end

return M
