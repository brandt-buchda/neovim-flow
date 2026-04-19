local M = {}

local function bootstrap_lazy()
  local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local out = vim.fn.system({
      'git', 'clone', '--filter=blob:none', '--branch=stable',
      'https://github.com/folke/lazy.nvim.git', lazypath,
    })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_err_writeln('failed to clone lazy.nvim:\n' .. out)
      return false
    end
  end
  vim.opt.rtp:prepend(lazypath)
  return true
end

function M.setup(_)
  if not bootstrap_lazy() then return end

  local specs = {
    require('neovim-flow.style').spec,
    require('neovim-flow.treesitter').spec,
  }
  for _, s in ipairs(require('neovim-flow.lsp').specs) do
    table.insert(specs, s)
  end

  require('lazy').setup(specs, {
    install = { colorscheme = { 'catppuccin' } },
    change_detection = { notify = false },
  })
end

return M
