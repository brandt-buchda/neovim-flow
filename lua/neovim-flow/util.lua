local M = {}

function M.notify(msg, level)
  vim.notify('[neovim-flow] ' .. msg, level or vim.log.levels.INFO)
end

function M.err(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

function M.run(cmd, opts)
  opts = opts or {}
  return vim.system(cmd, { text = true, cwd = opts.cwd }):wait()
end

function M.repo_root()
  local result = M.run({ 'git', 'rev-parse', '--show-toplevel' })
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout)
end

function M.is_git_repo()
  return M.repo_root() ~= nil
end

function M.git_common_dir()
  local root = M.repo_root()
  if not root then return nil end
  local r = M.run({ 'git', 'rev-parse', '--git-common-dir' }, { cwd = root })
  if r.code ~= 0 then return nil end
  local g = vim.trim(r.stdout)
  if g:sub(1, 1) == '/' or g:match('^%a:') then
    return g
  end
  return root .. '/' .. g
end

function M.ensure_exclude(repo_root, pattern)
  local exclude_path = repo_root .. '/.git/info/exclude'
  local f = io.open(exclude_path, 'r')
  if f then
    for line in f:lines() do
      if vim.trim(line) == pattern then
        f:close()
        return
      end
    end
    f:close()
  end
  local w = io.open(exclude_path, 'a')
  if w then
    w:write(pattern .. '\n')
    w:close()
  end
end

function M.sanitize_name(name)
  return (name:gsub('[^%w%-_]', '-'))
end

return M
