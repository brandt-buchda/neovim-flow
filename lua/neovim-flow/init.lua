local M = {}

function M.setup(opts)
  opts = opts or {}
  require('neovim-flow.config').apply(opts)
  require('neovim-flow.plugins').setup(opts)
  require('neovim-flow.tab').setup(opts)
  require('neovim-flow.diff').setup(opts)
  require('neovim-flow.session').setup(opts)
  require('neovim-flow.keymaps').apply(opts)
end

return M
