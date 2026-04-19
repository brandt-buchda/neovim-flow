; Extend default Python highlights:
;   * Allow leading underscore(s) on SCREAMING_CASE constants.
;     Default captures ^[A-Z][A-Z0-9_]*$ which excludes _SOME_CONSTANT.

((identifier) @constant
 (#match? @constant "^_+[A-Z][A-Z0-9_]*$")
 (#set! "priority" 120))
