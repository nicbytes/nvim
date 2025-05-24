; KDI Syntax Highlighting
; Move this to your ~/.config/nvim/queries/kdi/
; `cp scripts/tree-sitter-kdi/queries/kdi/highlights.scm ~/.config/nvim/queries/kdi/highlights.scm`

; Comments
(line_comment) @comment
(block_comment) @comment

; Keywords
[
  "revision"
  "schema"
  "type"
] @keyword

[
  "prop"
  "array"
  "const"
] @keyword.type

[
  "desc"
  "widgets"
  "constraints"
  "actions"
] @tag.attribute


[
  "if"
  "else"
  "match"
] @keyword.conditional

[
  "for"
  "in"
] @keyword.repeat

[
  "break"
  "fail"
] @keyword.exception

; Identifiers
(identifier) @variable

; Type identifiers (assuming they follow convention)
((identifier) @type
  (#lua-match? @type "^[A-Z]"))

; Description tags
(description_tag) @attribute

; Literals
(string_literal) @string
(template_string) @string
(template_string_content) @string
(escape_sequence) @string.escape
(template_expression) @none

; Inside template expressions, highlight normally
(template_expression
  "{" @punctuation.special
  (_) @none
  "}" @punctuation.special)

(number) @number
(boolean) @boolean

; Operators
[
  "&&"
  "||"
  "=="
  "!="
  "<"
  "<="
  ">"
  ">="
  "+"
  "-"
  "*"
  "/"
  "%"
  "!"
  "|"
] @operator

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  ";"
  ","
  ":"
  "::"
  "."
  "=>"
] @punctuation.delimiter

; Function calls
(method_call
  method: (identifier) @function.method)

; Property access
(property_access
  property: (identifier) @variable.member)

; Match expressions
(match_expression
  "match" @keyword.conditional)

(match_arm
  pattern: (identifier) @variable.parameter
  "(" @punctuation.bracket
  local: (identifier) @variable.parameter
  ")" @punctuation.bracket)



; Labeled expressions
(labeled_expression
  label: (string_literal) @string.special)

(widgets_strict) @keyword
(widgets_default) @keyword

; Widget declarations
(widgets_attribute
  (identifier) @constant)

; Action declarations
(action_declaration
  (action_keyword) @property)

; Type expressions
(type_expression
  (identifier) @type)

(union_type
  "|" @operator)

; Constants
(const_attribute
  (identifier) @constant.rust)

; Special highlighting for fail messages
(fail_expression
  "fail" @keyword.exception
  (string_literal) @string.special)

(fail_expression
  "fail" @keyword.exception
  (template_string) @string.special)

; Special highlighting for break expressions
(break_expression
  "break" @keyword.exception)
