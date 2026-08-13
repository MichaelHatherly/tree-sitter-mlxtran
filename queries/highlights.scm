; Sections and blocks
(section_name) @type
(block_name) @keyword

; Assignment and derivative targets
(assignment target: (identifier) @variable)
(derivative) @function.macro

; Calls
(call function: (identifier) @function.call)

; Attribute keys and bare flags
(pair key: (identifier) @property)
(flag) @attribute

; Literals
(number) @number
(string) @string
(comment) @comment
(description_text) @comment

; Operators and control keywords
["+" "-" "*" "/" "^" "==" "!=" "~=" "<=" ">=" "<" ">" "&&" "||" "&" "|" "!" "~" "="] @operator
["if" "else" "end"] @keyword.control

; Punctuation
["{" "}" "(" ")" "[" "]" "<" ">"] @punctuation.bracket
"," @punctuation.delimiter
