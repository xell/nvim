((html_tag) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined))

; Pandoc tex_math_dollars rules, so prose currency like "$5,000–$10,000" is
; not math: the opening $ is not followed by a space, the closing $ does not
; follow a space, and (dollar-math?, plugin/markdown_math_dollars.lua) the
; closing $ is not followed by a digit.
((latex_block) @injection.content
  (#not-lua-match? @injection.content "^%$+%s")
  (#not-lua-match? @injection.content "%s%$+$")
  (#dollar-math? @injection.content)
  (#set! injection.language "latex")
  (#set! injection.include-children))
