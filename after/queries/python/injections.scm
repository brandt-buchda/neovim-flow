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
 (#match? @injection.language "language=[%w_]+")
 (#gsub! @injection.language ".*language=([%w_]+).*" "%1")
 (#set! injection.combined))

((comment) @injection.language
 .
 (expression_statement
   (string (string_content) @injection.content))
 (#match? @injection.language "language=[%w_]+")
 (#gsub! @injection.language ".*language=([%w_]+).*" "%1")
 (#set! injection.combined))

; --- Name-based heuristics ----------------------------------------------------
; Using injection.combined so that triple-quoted strings, which may contain
; multiple string_content chunks split by escape sequences / interpolation,
; are treated as a single injected block.

; *_sql / *_query -> sql
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[sS][qQ][lL]$")
 (#set! injection.language "sql")
 (#set! injection.combined))

((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[qQ][uU][eE][rR][yY]$")
 (#set! injection.language "sql")
 (#set! injection.combined))

; *_json -> json
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[jJ][sS][oO][nN]$")
 (#set! injection.language "json")
 (#set! injection.combined))

; *_html -> html
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[hH][tT][mM][lL]$")
 (#set! injection.language "html")
 (#set! injection.combined))

; *_xml -> xml
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[xX][mM][lL]$")
 (#set! injection.language "xml")
 (#set! injection.combined))

; *_yaml / *_yml -> yaml
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[yY][aA]?[mM][lL]$")
 (#set! injection.language "yaml")
 (#set! injection.combined))

; *_css -> css
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[cC][sS][sS]$")
 (#set! injection.language "css")
 (#set! injection.combined))

; *_js -> javascript
((assignment
   left: (identifier) @_name
   right: (string (string_content) @injection.content))
 (#match? @_name "[jJ][sS]$")
 (#set! injection.language "javascript")
 (#set! injection.combined))
