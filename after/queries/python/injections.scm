; Extend default Python injections with:
;   1. # language=<lang>  directive comments
;   2. Variable-name heuristics: *_sql / *_query -> sql,
;                                *_json          -> json,
;                                *_html          -> html,
;                                *_xml           -> xml,
;                                *_yaml / *_yml  -> yaml,
;                                *_css           -> css,
;                                *_js            -> javascript

; --- # language=<lang> directive ---------------------------------------------
; Usage:
;   # language=sql
;   query = """SELECT * FROM t"""

((comment) @injection.language
 .
 (expression_statement
   (assignment
     right: [
       (string (string_content) @injection.content)
       (concatenated_string (string (string_content) @injection.content))
     ]))
 (#lua-match? @injection.language "language=[%w_]+")
 (#gsub! @injection.language ".*language=([%w_]+).*" "%1"))

; Same, but for bare string expressions (e.g. docstrings, return values)
((comment) @injection.language
 .
 (expression_statement
   (string (string_content) @injection.content))
 (#lua-match? @injection.language "language=[%w_]+")
 (#gsub! @injection.language ".*language=([%w_]+).*" "%1"))

; --- Name-based heuristics ----------------------------------------------------
; *_sql / *_query -> sql
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[sS][qQ][lL]$")
 (#set! injection.language "sql"))

((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[qQ]uery$")
 (#set! injection.language "sql"))

; *_json -> json
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[jJ][sS][oO][nN]$")
 (#set! injection.language "json"))

; *_html -> html
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[hH][tT][mM][lL]$")
 (#set! injection.language "html"))

; *_xml -> xml
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[xX][mM][lL]$")
 (#set! injection.language "xml"))

; *_yaml / *_yml -> yaml
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[yY][aA]?[mM][lL]$")
 (#set! injection.language "yaml"))

; *_css -> css
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[cC][sS][sS]$")
 (#set! injection.language "css"))

; *_js -> javascript
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#lua-match? @_name "_[jJ][sS]$")
 (#set! injection.language "javascript"))
