local util = require('neovim-flow.util')

local M = {}

local function branch_exists(root, branch)
  local r = util.run({ 'git', 'show-ref', '--verify', '--quiet', 'refs/heads/' .. branch }, { cwd = root })
  return r.code == 0
end

local function remote_branch_exists(root, branch)
  local r = util.run({ 'git', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/' .. branch }, { cwd = root })
  return r.code == 0
end

local function find_worktree(root, path)
  for _, wt in ipairs(M.list(root)) do
    if wt.path == path then return wt end
  end
  return nil
end

local function find_worktree_by_branch(root, branch)
  local ref = 'refs/heads/' .. branch
  for _, wt in ipairs(M.list(root)) do
    if wt.branch == ref or wt.branch == branch then return wt end
  end
  return nil
end

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

  local path = root .. '/.worktrees/' .. clean
  local branch = clean

  local existing = find_worktree(root, path)
  if existing then
    return {
      path = path,
      branch = (existing.branch or branch):gsub('^refs/heads/', ''),
      name = clean,
      root = root,
      existed = true,
    }
  end

  util.notify('fetching origin...')
  local fetch = util.run({ 'git', 'fetch', 'origin' }, { cwd = root })
  if fetch.code ~= 0 then
    return nil, 'git fetch failed: ' .. (fetch.stderr or '')
  end

  local elsewhere = find_worktree_by_branch(root, branch)
  if elsewhere then
    util.notify('reusing existing worktree at ' .. elsewhere.path)
    return {
      path = elsewhere.path,
      branch = branch,
      name = clean,
      root = root,
      existed = true,
    }
  end

  local add
  local pushed = false
  if branch_exists(root, branch) then
    util.notify('attaching worktree to existing branch ' .. branch .. '...')
    add = util.run({ 'git', 'worktree', 'add', path, branch }, { cwd = root })
  elseif remote_branch_exists(root, branch) then
    util.notify('creating worktree from origin/' .. branch .. '...')
    add = util.run({ 'git', 'worktree', 'add', '-b', branch, path, 'origin/' .. branch }, { cwd = root })
  else
    util.notify('creating branch ' .. branch .. ' from origin/main...')
    add = util.run({ 'git', 'worktree', 'add', '-b', branch, path, 'origin/main' }, { cwd = root })
    pushed = true
  end
  if add.code ~= 0 then
    return nil, 'worktree add failed: ' .. (add.stderr or '')
  end

  if pushed then
    util.notify('pushing ' .. branch .. ' to origin...')
    local push = util.run({ 'git', 'push', '-u', 'origin', branch }, { cwd = path })
    if push.code ~= 0 then
      util.err('push failed: ' .. (push.stderr or ''))
    end
  end

  return { path = path, branch = branch, name = clean, root = root, existed = false }
end

function M.remove(path, root)
  if vim.fn.isdirectory(path) == 1 then
    local result = util.run(
      { 'git', 'worktree', 'remove', '--force', path },
      { cwd = root }
    )
    if result.code == 0 then
      return true
    end
  end
  local prune = util.run({ 'git', 'worktree', 'prune' }, { cwd = root })
  if prune.code ~= 0 then
    return false, prune.stderr or 'worktree prune failed'
  end
  return true
end

function M.prune(root)
  local r = util.run({ 'git', 'worktree', 'prune' }, { cwd = root })
  if r.code ~= 0 then
    return false, r.stderr or 'worktree prune failed'
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

function M.list_agents(root)
  root = root or util.repo_root()
  if not root then return {} end
  local prefix = root .. '/.worktrees/'
  local agents = {}
  for _, wt in ipairs(M.list(root)) do
    if wt.path:sub(1, #prefix) == prefix then
      local name = wt.path:sub(#prefix + 1)
      local branch = (wt.branch or ''):gsub('^refs/heads/', '')
      table.insert(agents, {
        path = wt.path,
        name = name,
        branch = branch,
        root = root,
      })
    end
  end
  return agents
end

return M
