; Extend default Python highlights:
;   * Allow leading underscore(s) on SCREAMING_CASE constants.
;     Default captures ^[A-Z][A-Z0-9_]*$ which excludes _SOME_CONSTANT.

((identifier) @constant
 (#lua-match? @constant "^_+[A-Z][A-Z0-9_]*$"))
