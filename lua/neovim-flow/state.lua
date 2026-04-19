local util = require('neovim-flow.util')

local M = {}

local function state_path()
  local gdir = util.git_common_dir()
  if not gdir then return nil end
  return gdir .. '/neovim-flow-agents.json'
end

function M.load()
  local p = state_path()
  if not p then return {} end
  local f = io.open(p, 'r')
  if not f then return {} end
  local content = f:read('*a')
  f:close()
  if not content or content == '' then return {} end
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok or type(data) ~= 'table' then return {} end
  return data
end

function M.save(data)
  local p = state_path()
  if not p then return end
  local f = io.open(p, 'w')
  if not f then return end
  f:write(vim.fn.json_encode(data))
  f:close()
end

function M.upsert(name, entry)
  local data = M.load()
  data[name] = entry
  M.save(data)
end

function M.remove(name)
  local data = M.load()
  data[name] = nil
  M.save(data)
end

return M
