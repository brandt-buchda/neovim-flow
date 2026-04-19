local M = {}

local highlight_extensions = [[
;; extensions: constants (with optional leading underscores) + dict keys

((identifier) @constant
 (#lua-match? @constant "^_*[A-Z][A-Z0-9_]*$")
 (#set! "priority" 125))

(dictionary
  (pair
    key: (string) @property))

(dictionary
  (pair
    key: (identifier) @property))

(keyword_argument
  name: (identifier) @variable.parameter)
]]

local injection_extensions = [[
;; extensions: # language=X directive + name heuristics

((comment) @injection.language
 .
 (expression_statement
   (assignment
     right: (string) @injection.content))
 (#lua-match? @injection.language "language=[%w_]+")
 (#gsub! @injection.language ".*language=([%w_]+).*" "%1")
 (#set! injection.include-children))

((comment) @injection.language
 .
 (expression_statement
   (string) @injection.content)
 (#lua-match? @injection.language "language=[%w_]+")
 (#gsub! @injection.language ".*language=([%w_]+).*" "%1")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[sS][qQ][lL]$")
 (#set! injection.language "sql")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[qQ][uU][eE][rR][yY]$")
 (#set! injection.language "sql")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[jJ][sS][oO][nN]$")
 (#set! injection.language "json")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[hH][tT][mM][lL]$")
 (#set! injection.language "html")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[xX][mM][lL]$")
 (#set! injection.language "xml")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[yY][aA]?[mM][lL]$")
 (#set! injection.language "yaml")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[cC][sS][sS]$")
 (#set! injection.language "css")
 (#set! injection.include-children))

((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[jJ][sS]$")
 (#set! injection.language "javascript")
 (#set! injection.include-children))
]]

local function read_file(path)
  local f = io.open(path, 'rb')
  if not f then return '' end
  local contents = f:read('*a') or ''
  f:close()
  return contents
end

local function merge_query(lang, kind, extra)
  local files = vim.api.nvim_get_runtime_file(('queries/%s/%s.scm'):format(lang, kind), true)
  local after = vim.api.nvim_get_runtime_file(('after/queries/%s/%s.scm'):format(lang, kind), true)
  local parts = {}
  for _, p in ipairs(files) do table.insert(parts, read_file(p)) end
  for _, p in ipairs(after) do table.insert(parts, read_file(p)) end
  table.insert(parts, extra)
  vim.treesitter.query.set(lang, kind, table.concat(parts, '\n'))
end

local function apply_python_extensions()
  local ok = pcall(vim.treesitter.language.inspect, 'python')
  if not ok then return end
  merge_query('python', 'highlights', highlight_extensions)
  merge_query('python', 'injections', injection_extensions)
end

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
  config = function(_, opts)
    require('nvim-treesitter.configs').setup(opts)
    apply_python_extensions()

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'python',
      callback = apply_python_extensions,
    })
  end,
}

return M
