; ==============================
; Firebase Security Rules — Highlights
; ==============================

; -------- Comments --------
(comment) @comment

; -------- Keywords --------
[
  "service"
  "match"
  "allow"
  "function"
  "return"
  "let"
  "if"
  "in"
  "is"
] @keyword

(rules_version_statement
  "rules_version" @keyword
  "=" @operator
  ";" @punctuation.delimiter)

; -------- Operators / Delimiters --------
[
  "&&" "||" "!"
  "==" "!=" "<" "<=" ">" ">="
  "+" "-" "*" "/" "%"
  "?" ":" "," ";"
  "." "="
] @operator

[
  "(" ")" "[" "]" "{" "}"
] @punctuation.bracket

; -------- Literals / Types --------
(string_literal)  @string
(number)          @number
(boolean_literal) @boolean
(null_literal)    @constant.builtin
(type_literal)    @type.builtin

; -------- Services / Namespaces --------
(service_name) @namespace

; -------- Declarations --------
(function_decl
  "function" @keyword
  name: (identifier) @function)

(parameter_list (identifier) @variable.parameter)

(local_variable
  "let" @keyword
  (identifier) @variable
  "=" @operator)

(return_statement "return" @keyword)

; -------- Allow rules --------
(allow_decl
  "allow" @keyword
  (action_list
    (identifier) @keyword
    (#match? @keyword "^(read|write|get|list|create|update|delete)$"))
  (":" @punctuation.delimiter)?
  ("if" @keyword)?)

; Also catch subsequent comma-separated actions
(allow_decl
  (action_list
    ("," @punctuation.delimiter)?
    (identifier) @keyword
    (#match? @keyword "^(read|write|get|list|create|update|delete)$")))

; -------- Calls / Members --------
; Function call callee (simple identifier)
(call_expression
  function: (identifier) @function)

; Function call callee (qualified: a.b or a.b.c)
(call_expression
  function: (member
    .
    (identifier)
    .
    (identifier) @function))

; Member/property access chain
(member
  (identifier) @variable
  ("." @operator (identifier) @property)+)

; -------- Built-in Identifiers --------
; Top-level built-ins
((identifier) @variable.builtin
  (#match? @variable.builtin "^(request|resource)$"))

; Built-in namespaces
((identifier) @namespace.builtin
  (#match? @namespace.builtin "^(math|hashing|latlng|timestamp|duration|firestore)$"))

; Built-in global functions
((identifier) @function.builtin
  (#match? @function.builtin "^(get|exists|getAfter|existsAfter|debug)$"))

; Built-in firestore.* bridge (method piece)
((member
   (identifier) @namespace
   (identifier) @function.builtin)
  (#match? @namespace "^(firestore)$")
  (#match? @function.builtin "^(get|exists)$"))

; Common instance methods (strings, lists, sets, maps, timestamps, durations, latlng)
((identifier) @function.builtin
  (#match? @function.builtin
    "^(matches|split|replace|lower|upper|size|contains|startsWith|endsWith|toUtf8|join|toSet|hasAll|hasAny|hasOnly|removeAll|keys|values|get|diff|addedKeys|removedKeys|changedKeys|affectedKeys|unchangedKeys|union|intersection|difference|date|time|year|month|day|hours|minutes|seconds|nanos|dayOfWeek|dayOfYear|toMillis|latitude|longitude|distance)$"))

; -------- Paths --------
; Match paths
(path_expression "/" @punctuation.delimiter)
(path_literal_segment) @string.special

(path_parameter
  "{" @punctuation.bracket
  (identifier) @variable.parameter
  "}" @punctuation.bracket)

(path_recursive_wildcard
  "{" @punctuation.bracket
  (identifier) @variable.parameter
  "=**" @operator
  "}" @punctuation.bracket)

; Interpolation $(...)
(path_interpolation
  "$" @punctuation.special
  "(" @punctuation.bracket
  ")" @punctuation.bracket)

; Paths in get/exists arguments
(path_argument "/" @punctuation.delimiter)
(path_literal_segment_arg) @string.special

; Root path argument ("/")
(path_root) @string.special
