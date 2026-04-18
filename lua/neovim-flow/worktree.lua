local util = require('neovim-flow.util')

local M = {}

function M.create(name)
  local root = util.repo_root()
  if not root then
    return nil, 'not a git repository'
  end

  local clean = util.sanitize_name(name)
  if clean == '' then
    return nil, 'invalid worktree name'
  end

  util.ensure_exclude(root, '.worktrees/')

  util.notify('fetching origin...')
  local fetch = util.run({ 'git', 'fetch', 'origin' }, { cwd = root })
  if fetch.code ~= 0 then
    return nil, 'git fetch failed: ' .. (fetch.stderr or '')
  end

  local path = root .. '/.worktrees/' .. clean
  local branch = 'agent/' .. clean

  util.notify('creating worktree ' .. clean .. '...')
  local add = util.run(
    { 'git', 'worktree', 'add', '-b', branch, path, 'origin/main' },
    { cwd = root }
  )
  if add.code ~= 0 then
    return nil, 'worktree add failed: ' .. (add.stderr or '')
  end

  return { path = path, branch = branch, name = clean, root = root }
end

function M.remove(path, root)
  local result = util.run(
    { 'git', 'worktree', 'remove', '--force', path },
    { cwd = root }
  )
  if result.code ~= 0 then
    return false, result.stderr or 'worktree remove failed'
  end
  return true
end

function M.list(root)
  local result = util.run({ 'git', 'worktree', 'list', '--porcelain' }, { cwd = root })
  if result.code ~= 0 then
    return {}
  end
  local worktrees = {}
  local current
  for line in result.stdout:gmatch('[^\r\n]+') do
    if line:match('^worktree ') then
      if current then table.insert(worktrees, current) end
      current = { path = line:sub(10) }
    elseif line:match('^branch ') and current then
      current.branch = line:sub(8)
    end
  end
  if current then table.insert(worktrees, current) end
  return worktrees
end

return M
