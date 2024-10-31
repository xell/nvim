syntax case ignore
" must not use syntax clear lest the override / redefinition won't work
"syntax clear
syntax spell toplevel

syn match   xTemp      '{=[^=][^}]\{-}}' containedin=ALLBUT,cmHighlight,cmHighlightLeft,cmHighlightRight
syn match   cmHighlight      '{==[^=].\{-}==}' contains=@Spell,cmHighlightLeft,cmHighlightRight
syn match   cmHighlightLeft  '{==' contained conceal
syn match   cmHighlightRight '==}' contained conceal

"syn match markdownListMarkerConceal "\%(\t\| \{0,4\}\)\zs[-*+]\ze\%(\s\+\S\)\@=" conceal cchar=
syn match markdownListMarkerConceal "\%(\t\|\s\+\)\zs[-*+]\ze\%(\s\+\S\)\@=" conceal cchar=

hi default link xTemp Type
hi default link cmHighlight RedrawDebugComposed
" ori Delimiter
hi! default link markdownCodeDelimiter String
hi! default link markdownCode @string

"syn region markdownIdDeclaration matchgroup=markdownLinkDelimiter start="^ \{0,3\}!\=\[" end="\]:" oneline keepend skipwhite

" ori Typedef
hi! default link markdownFootnote @markup.underline
" ori Typedef
hi! default link markdownIdDeclaration @markup.underline
" ori htmlBold | Keyword
hi! default link markdownBold @markup.strong
"hi! default link markdownBold textBold
" ori htmlItalic | Special
hi! default link markdownItalic @markup.italic
"hi! default link markdownItalic textItalic

hi! default link markdownH1 NONE
hi! default link @markup.raw.markdown_inline @string

hi! default link @markup.strikethrough.markdown_inline Conceal
