; Extend default Python highlights.
;
; NOTE: predicates
;   #match?      -> vim regex (needs \+ for one-or-more)
;   #lua-match?  -> lua patterns (+ works). Registered by nvim-treesitter.
; Priority bumped above the default @variable catch-all (which is 100).

; --- Constants: _CONST / __CONST / CONST ----------------------------------------
((identifier) @constant
 (#lua-match? @constant "^_*[A-Z][A-Z0-9_]*$")
 (#set! "priority" 125))

; --- Dict keys: string literals and identifier shorthand -------------------------
(dictionary
  (pair
    key: (string) @property))

(dictionary
  (pair
    key: (identifier) @property))

; keyword arguments (foo(key=value)) → parameter
(keyword_argument
  name: (identifier) @variable.parameter)
