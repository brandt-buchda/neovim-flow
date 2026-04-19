; Extend default Python injections:
;   1. # language=<lang>  directive comments
;   2. Variable-name heuristics
;
; Uses #lua-match? (Lua patterns via nvim-treesitter). Uses the whole
; (string) node with injection.include-children so triple-quoted strings
; with newlines / escapes are captured as a single block.

; --- # language=<lang> directive ---------------------------------------------

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

; --- Name-based heuristics ----------------------------------------------------

; *_sql / *_query -> sql
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

; *_json -> json
((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[jJ][sS][oO][nN]$")
 (#set! injection.language "json")
 (#set! injection.include-children))

; *_html -> html
((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[hH][tT][mM][lL]$")
 (#set! injection.language "html")
 (#set! injection.include-children))

; *_xml -> xml
((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[xX][mM][lL]$")
 (#set! injection.language "xml")
 (#set! injection.include-children))

; *_yaml / *_yml -> yaml
((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[yY][aA]?[mM][lL]$")
 (#set! injection.language "yaml")
 (#set! injection.include-children))

; *_css -> css
((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[cC][sS][sS]$")
 (#set! injection.language "css")
 (#set! injection.include-children))

; *_js -> javascript
((assignment
   left: (identifier) @_name
   right: (string) @injection.content)
 (#lua-match? @_name "[jJ][sS]$")
 (#set! injection.language "javascript")
 (#set! injection.include-children))
